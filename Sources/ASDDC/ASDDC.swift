import AppleSiliconDDC
import ArgumentParser
import Darwin

enum DDCError: Error {
  case runtimeError(String)
}

@main
struct ASDDC: ParsableCommand {
  static var configuration = CommandConfiguration(
    abstract: "AppleSiliconDDC",
    subcommands: [Detect.self, GetVCP.self, SetVCP.self, Capabilities.self],
    defaultSubcommand: Detect.self)

  struct HexOption: ParsableArguments {
    @Argument(
      help: "Raw VCP code (decimal or hex prefixed with 0x or x)",
      transform: { (value: String) throws -> Int in
        if value.lowercased().hasPrefix("0x") {
          guard let intValue = Int(value.dropFirst(2), radix: 16) else {
            throw ValidationError("Invalid hex value: \(value)")
          }
          return intValue
        } else if value.lowercased().hasPrefix("x") {
          guard let intValue = Int(value.dropFirst(1), radix: 16) else {
            throw ValidationError("Invalid hex value: \(value)")
          }
          return intValue
        } else {
          guard let intValue = Int(value) else {
            throw ValidationError("Invalid integer value: \(value)")
          }
          return intValue
        }
      })
    var value: Int
  }
  struct VCPOptions: ParsableArguments {
    @Flag(help: "Terse output (similar to ddcutil --terse)")
    var terse = false

    @Option(
      name: [.customShort("n"), .customLong("sn")],
      help:
        "Alphanumeric serial number of target device. If omitted, first working display will be tried."
    )
    var serial: String?
    @Option(
      name: [.customShort("d"), .customLong("display"), .customLong("dis")],
      help: "ioDisplayLocation of target device. If omitted, first working display will be tried."
    )
    var ioDisplayLocation: String?
    @Option(
      name: [.customShort("e"), .customLong("edid")],
      help: "EDID of target device. If omitted, first working display will be tried."
    )
    var edidUUID: String?

  }
  struct Detect: ParsableCommand {
    static var configuration = CommandConfiguration(abstract: "Detect connected display.")

    mutating func run() {
      let displays = AppleSiliconDDC.getIoregServicesForMatching()
      for display in displays {
        if display.edidUUID == "" && display.manufacturerID == "" && display.transportUpstream == ""
          && display.transportDownstream == ""
        {
          continue
        }
        print(display.ioDisplayLocation)
        print(
          String(format: "  product name:  (%@) %@", display.manufacturerID, display.productName))
        print(String(format: "  serial number: %@", display.alphanumericSerialNumber))
        print(
          String(
            format: "  connectors:    %@ -> %@", display.transportUpstream,
            display.transportDownstream))
      }
    }
  }
  struct Capabilities: ParsableCommand {
    static var configuration = CommandConfiguration(abstract: "Qeuery all VCPs.")
    @OptionGroup var options: ASDDC.VCPOptions

    mutating func run() throws {
      let matchedDisplays = matchService(options: options)
      if matchedDisplays.count == 0 {
        throw DDCError.runtimeError("Didn't match any display")
      }
      let display = matchedDisplays[0]
      for vcp in 0...255 {
        var args = Array(CommandLine.arguments.dropFirst().dropFirst())
        args.append(String(format: "0x%X", vcp))
        var getVcpInstance = try GetVCP.parse(args)
        try getVcpInstance.read(display: display)
      }
    }
  }

  static func matchService(options: VCPOptions) -> [AppleSiliconDDC.IOregService] {
    let allDisplays = AppleSiliconDDC.getIoregServicesForMatching()
    var matchedDisplays: [AppleSiliconDDC.IOregService] = []
    for display in allDisplays {
      if display.edidUUID == "" && display.manufacturerID == "" && display.transportUpstream == ""
        && display.transportDownstream == ""
      {
        continue
      }
      if options.serial == nil && options.ioDisplayLocation == nil && options.edidUUID == nil {
        matchedDisplays.append(display)
      } else if display.alphanumericSerialNumber == options.serial
        || display.ioDisplayLocation == options.ioDisplayLocation
        || display.edidUUID == options.edidUUID
      {
        matchedDisplays.append(display)
      }
    }
    return matchedDisplays
  }

  static func transformHexOrDecimalSingle(_ value: String) throws -> Int {
    return try transformHexOrDecimal(value, max: 0xFF)
  }
  static func transformHexOrDecimalDouble(_ value: String) throws -> Int {
    return try transformHexOrDecimal(value, max: 0xFFFF)
  }
  static func transformHexOrDecimal(_ value: String, max: Int) throws -> Int {
    var finalIntValue: Int
    if value.lowercased().hasPrefix("0x") {
      guard let intValue = Int(value.dropFirst(2), radix: 16) else {
        throw ValidationError("Invalid hex value: \(value)")
      }
      finalIntValue = intValue
    } else if value.lowercased().hasPrefix("x") {
      guard let intValue = Int(value.dropFirst(1), radix: 16) else {
        throw ValidationError("Invalid hex value: \(value)")
      }
      finalIntValue = intValue
    } else {
      guard let intValue = Int(value) else {
        throw ValidationError("Invalid integer value: \(value)")
      }
      finalIntValue = intValue
    }
    if finalIntValue < 0 || finalIntValue > max {
      throw ValidationError("Value: \(value) not in range 0 ... \(max)")
    }
    return finalIntValue
  }

  struct GetVCP: ParsableCommand {
    static var configuration = CommandConfiguration(
      commandName: "getvcp", abstract: "Read value for given VCP.")

    @OptionGroup var options: ASDDC.VCPOptions
    @Argument(
      help: "Raw VCP code (decimal or hex prefixed with 0x or x)",
      transform: transformHexOrDecimalSingle)
    var vcp: Int

    mutating func run() throws {
      let matchedDisplays = matchService(options: options)
      if matchedDisplays.count == 0 {
        throw DDCError.runtimeError("Didn't match any display")
      }
      let display = matchedDisplays[0]
      try read(display: display)
    }
    mutating func read(display: AppleSiliconDDC.IOregService) throws {
      let value = AppleSiliconDDC.read(service: display.service, command: UInt8(exactly: vcp)!)
      if !(value == nil) {
        let sl = value!.current & 0x00FF
        let sh = value!.current >> 8
        let ml = value!.max & 0x00FF
        let mh = value!.max >> 8
        if options.terse {
          print(String(format: "VCP %02X VALUE %02X %02X %02X %02X", vcp, mh, ml, sh, sl))
        } else {
          print(
            String(
              format:
                "VCP code 0x%02X (Non-interpretable by this tool): mh=0x%02X, ml=0x%02X, sh=0x%02X, sl=0x%02X",
              vcp, mh, ml, sh, sl))
        }
      } else {
        throw DDCError.runtimeError("Failure when reading")
      }
    }
  }

  struct SetVCP: ParsableCommand {
    static var configuration = CommandConfiguration(
      commandName: "setvcp", abstract: "Sets value for given VCP.")

    @Flag(
      name: [.customLong("noverify")],
      help: "Do not read VCP value after setting it"
    )
    var noVerify = false
    @Flag(
      name: [.customLong("verify-single")],
      help: "Read VCP value after setting it, but only check lower byte"
    )
    var verifySingle = false

    @OptionGroup var options: ASDDC.VCPOptions
    @Argument(
      help: "Raw VCP code (decimal or hex prefixed with 0x or x)",
      transform: transformHexOrDecimalSingle)
    var vcp: Int
    @Argument(
      help: "Raw VCP value (decimal or hex prefixed with 0x or x)",
      transform: transformHexOrDecimalDouble)
    var value: Int

    mutating func run() throws {
      let matchedDisplays = matchService(options: options)
      if matchedDisplays.count == 0 {
        throw DDCError.runtimeError("Didn't match any display")
      }
      let display = matchedDisplays[0]
      let writeOK = AppleSiliconDDC.write(
        service: display.service, command: UInt8(exactly: vcp)!, value: UInt16(exactly: value)!)
      if !writeOK {
        throw DDCError.runtimeError("Failure when writing")
      } else if noVerify {
        print("Write OK")
      } else {
        let retrievedValues = AppleSiliconDDC.read(
          service: display.service, command: UInt8(exactly: vcp)!)
        if retrievedValues == nil {
          throw DDCError.runtimeError("Failure when reading back")
        }
        var checkOK = false
        if verifySingle {
          checkOK = (value & 0x00FF) == (retrievedValues!.current & 0x00FF)
        } else {
          checkOK = (value) == (retrievedValues!.current)
        }
        if !checkOK {
          throw DDCError.runtimeError("Failure when verifying")
        }
        print("Write OK")
      }
    }
  }
}
