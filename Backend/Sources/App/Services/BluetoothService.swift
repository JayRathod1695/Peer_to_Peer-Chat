#if os(macOS) || os(iOS)
import CoreBluetooth
import Foundation

// MARK: - BluetoothManager Class
public class BluetoothManager: NSObject {
    
    // MARK: - Properties
    private var centralManager: CBCentralManager!
    private var discoveredPeripherals: [CBPeripheral] = []
    public private(set) var connectedPeripheral: CBPeripheral?
    private var targetCharacteristic: CBCharacteristic?
    
    // IMPORTANT: Replace these UUIDs with your own unique ones!
    private let SERVICE_UUID = CBUUID(string: "E20A39F4-73F5-4BC4-A12F-17D1AD07A961")
    private let CHARACTERISTIC_UUID = CBUUID(string: "08590F7E-DB05-467E-8757-E2273E5F7A91")
    
    // Callbacks for external handling
    public var onBluetoothStateUpdate: ((CBManagerState) -> Void)?
    public var onPeripheralDiscovered: ((CBPeripheral, [String: Any], NSNumber) -> Void)?
    public var onConnectionAttemptFinished: ((Bool, CBPeripheral?, Error?) -> Void)?
    public var onServicesDiscovered: ((Result<Void, Error>) -> Void)?
    public var onCharacteristicsDiscovered: ((Result<Void, Error>) -> Void)?
    public var onMessageReceived: ((Data) -> Void)?
    public var onMessageSent: ((Bool, Error?) -> Void)?

    // MARK: - Initialization
    public override init() {
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: DispatchQueue.main)
    }
    
    // MARK: - Public Methods
    public func startScanning() {
        guard centralManager.state == .poweredOn else {
            print("Cannot scan: Bluetooth not powered on. State: \(centralManager.state.rawValue)")
            return
        }
        
        discoveredPeripherals.removeAll()
        print("Starting scan for service UUID: \(SERVICE_UUID)")
        centralManager.scanForPeripherals(withServices: [SERVICE_UUID], options: nil)
    }
    
    public func stopScanning() {
        guard centralManager.state == .poweredOn, centralManager.isScanning else { return }
        print("Stopping scan.")
        centralManager.stopScan()
    }
    
    public func connect(to peripheral: CBPeripheral) {
        guard centralManager.state == .poweredOn else {
            print("Cannot connect: Bluetooth not powered on.")
            onConnectionAttemptFinished?(false, nil, NSError(domain: "BluetoothManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "Bluetooth not powered on"]))
            return
        }
        
        print("Attempting to connect to: \(peripheral.name ?? "Unknown")")
        centralManager.connect(peripheral, options: nil)
    }
    
    public func disconnect() {
        guard let peripheral = connectedPeripheral else {
            print("No peripheral connected to disconnect.")
            return
        }
        print("Disconnecting from: \(peripheral.name ?? "Unknown")")
        centralManager.cancelPeripheralConnection(peripheral)
    }
    
    public func getDiscoveredPeripherals() -> [CBPeripheral] {
        return discoveredPeripherals
    }
    
    public func sendMessage(_ message: String) {
        guard let characteristic = targetCharacteristic,
              let peripheral = connectedPeripheral else {
            print("Cannot send message: Not connected or characteristic not found.")
            onMessageSent?(false, NSError(domain: "BluetoothManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "Not connected or characteristic not found"]))
            return
        }
        
        guard let data = message.data(using: .utf8) else {
            print("Failed to convert message to data.")
            onMessageSent?(false, NSError(domain: "BluetoothManager", code: -2, userInfo: [NSLocalizedDescriptionKey: "Failed to convert message to data"]))
            return
        }
        
        peripheral.writeValue(data, for: characteristic, type: .withResponse)
        print("Sent message: \(message)")
    }
    
    public func isConnected() -> Bool {
        return connectedPeripheral != nil
    }
}

// MARK: - CBCentralManagerDelegate
extension BluetoothManager: CBCentralManagerDelegate {
    
    public func centralManagerDidUpdateState(_ central: CBCentralManager) {
        print("Bluetooth state updated: \(central.state.rawValue)")
        onBluetoothStateUpdate?(central.state)
    }
    
    public func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        print("Discovered: \(peripheral.name ?? "Unknown") (RSSI: \(RSSI))")
        
        if !discoveredPeripherals.contains(where: { $0.identifier == peripheral.identifier }) {
            discoveredPeripherals.append(peripheral)
        }
        
        onPeripheralDiscovered?(peripheral, advertisementData, RSSI)
    }
    
    public func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        print("Connected to: \(peripheral.name ?? "Unknown")")
        connectedPeripheral = peripheral
        peripheral.delegate = self
        
        print("Discovering services...")
        peripheral.discoverServices([SERVICE_UUID])
        
        onConnectionAttemptFinished?(true, peripheral, nil)
    }
    
    public func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        let errorMessage = error?.localizedDescription ?? "Unknown error"
        print("Failed to connect to: \(peripheral.name ?? "Unknown"). Error: \(errorMessage)")
        onConnectionAttemptFinished?(false, peripheral, error)
    }
    
    public func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        let errorMessage = error?.localizedDescription ?? "No error"
        print("Disconnected from: \(peripheral.name ?? "Unknown"). Error: \(errorMessage)")
        
        if connectedPeripheral?.identifier == peripheral.identifier {
            connectedPeripheral = nil
            targetCharacteristic = nil
        }
    }
}

// MARK: - CBPeripheralDelegate
extension BluetoothManager: CBPeripheralDelegate {
    
    public func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        if let error = error {
            print("Error discovering services: \(error)")
            onServicesDiscovered?(.failure(error))
            return
        }
        
        guard let services = peripheral.services else {
            print("No services found.")
            onServicesDiscovered?(.failure(NSError(domain: "BluetoothManager", code: -2, userInfo: [NSLocalizedDescriptionKey: "No services discovered"])))
            return
        }
        
        print("Discovered \(services.count) service(s).")
        for service in services {
            print("  - Service UUID: \(service.uuid)")
            if service.uuid == SERVICE_UUID {
                print("    -> Found target service. Discovering characteristics...")
                peripheral.discoverCharacteristics([CHARACTERISTIC_UUID], for: service)
            }
        }
        onServicesDiscovered?(.success(()))
    }
    
    public func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        if let error = error {
            print("Error discovering characteristics: \(error)")
            onCharacteristicsDiscovered?(.failure(error))
            return
        }
        
        guard let characteristics = service.characteristics else {
            print("No characteristics found for service \(service.uuid).")
            onCharacteristicsDiscovered?(.failure(NSError(domain: "BluetoothManager", code: -3, userInfo: [NSLocalizedDescriptionKey: "No characteristics discovered for service"])))
            return
        }
        
        print("Discovered \(characteristics.count) characteristic(s) for service \(service.uuid).")
        for characteristic in characteristics {
            print("  - Characteristic UUID: \(characteristic.uuid), Properties: \(characteristic.properties)")
            if characteristic.uuid == CHARACTERISTIC_UUID {
                print("    -> Found target characteristic.")
                targetCharacteristic = characteristic
                
                if characteristic.properties.contains(.notify) {
                    print("    -> Enabling notifications for this characteristic.")
                    peripheral.setNotifyValue(true, for: characteristic)
                } else {
                    print("    -> Characteristic does not support notifications.")
                }
                
                onCharacteristicsDiscovered?(.success(()))
                return
            }
        }
        let notFoundError = NSError(domain: "BluetoothManager", code: -4, userInfo: [NSLocalizedDescriptionKey: "Target characteristic not found"])
        print("Error: \(notFoundError.localizedDescription)")
        onCharacteristicsDiscovered?(.failure(notFoundError))
    }
    
    public func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        if let error = error {
            print("Error updating value for characteristic \(characteristic.uuid): \(error)")
            return
        }
        
        guard let data = characteristic.value else {
            print("Received update with no data for characteristic \(characteristic.uuid)")
            return
        }
        
        print("Received data update on characteristic \(characteristic.uuid).")
        onMessageReceived?(data)
    }
    
    public func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        if let error = error {
            print("Error writing to characteristic \(characteristic.uuid): \(error)")
            onMessageSent?(false, error)
        } else {
            print("Successfully wrote to characteristic \(characteristic.uuid).")
            onMessageSent?(true, nil)
        }
    }
    
    public func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?) {
        if let error = error {
            print("Error changing notification state for \(characteristic.uuid): \(error)")
        } else {
            if characteristic.isNotifying {
                print("Notifications enabled for \(characteristic.uuid).")
            } else {
                print("Notifications disabled for \(characteristic.uuid).")
            }
        }
    }
}

#else
// Mock implementation for Linux or other platforms
import Foundation

public class BluetoothManager {
    public init() {}
    public func startScanning() {}
    public func stopScanning() {}
    public func connect(to peripheral: AnyObject) {}
    public func disconnect() {}
    public func getDiscoveredPeripherals() -> [AnyObject] { return [] }
    public func sendMessage(_ message: String) {}
    public var onBluetoothStateUpdate: ((Any) -> Void)?
    public var onPeripheralDiscovered: ((Any, [String: Any], Any) -> Void)?
    public var onConnectionAttemptFinished: ((Bool, Any?, Error?) -> Void)?
    public var onServicesDiscovered: ((Result<Void, Error>) -> Void)?
    public var onCharacteristicsDiscovered: ((Result<Void, Error>) -> Void)?
    public var onMessageReceived: ((Data) -> Void)?
    public var onMessageSent: ((Bool, Error?) -> Void)?
    public func isConnected() -> Bool { return false }
}
#endif