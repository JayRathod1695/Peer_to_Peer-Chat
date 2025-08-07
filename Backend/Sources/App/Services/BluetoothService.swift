import CoreBluetooth
import Foundation // For DispatchQueue, etc.

// MARK: - BluetoothManager Class
class BluetoothManager: NSObject {
    
    // MARK: - Properties
    private var centralManager: CBCentralManager!
    private var discoveredPeripherals: [CBPeripheral] = []
    private var connectedPeripheral: CBPeripheral?
    private var targetCharacteristic: CBCharacteristic? // Will be set after connection & discovery
    
    // IMPORTANT: Replace these UUIDs with your own unique ones!
    private let YOUR_SERVICE_UUID = CBUUID(string: "E20A39F4-73F5-4BC4-A12F-17D1AD07A961") // Example Service UUID
    private let YOUR_CHARACTERISTIC_UUID = CBUUID(string: "08590F7E-DB05-467E-8757-E2273E5F7A91") // Example Characteristic UUID (for read/write/notify)
    
    // Callbacks for external handling (e.g., updating UI or triggering Vapor routes)
    var onBluetoothStateUpdate: ((CBManagerState) -> Void)?
    var onPeripheralDiscovered: ((CBPeripheral, [String: Any], NSNumber) -> Void)?
    var onConnectionAttemptFinished: ((Bool, CBPeripheral?, Error?) -> Void)?
    var onServicesDiscovered: ((Result<Void, Error>) -> Void)?
    var onCharacteristicsDiscovered: ((Result<Void, Error>) -> Void)?
    var onMessageReceived: ((Data) -> Void)?

    // MARK: - Initialization
    override init() {
        super.init()
        // Initialize CBCentralManager on the main queue for delegate callbacks
        centralManager = CBCentralManager(delegate: self, queue: DispatchQueue.main)
    }
    
    // MARK: - Public Methods
    func startScanning() {
        guard centralManager.state == .poweredOn else {
            print("Cannot scan: Bluetooth not powered on. State: \(centralManager.state.rawValue)")
            return
        }
        
        discoveredPeripherals.removeAll()
        print("Starting scan for service UUID: \(YOUR_SERVICE_UUID)")
        centralManager.scanForPeripherals(withServices: [YOUR_SERVICE_UUID], options: nil)
    }
    
    func stopScanning() {
        guard centralManager.state == .poweredOn, centralManager.isScanning else { return }
        print("Stopping scan.")
        centralManager.stopScan()
    }
    
    func connect(to peripheral: CBPeripheral) {
        guard centralManager.state == .poweredOn else {
            print("Cannot connect: Bluetooth not powered on.")
            onConnectionAttemptFinished?(false, nil, NSError(domain: "BluetoothManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "Bluetooth not powered on"]))
            return
        }
        
        print("Attempting to connect to: \(peripheral.name ?? "Unknown")")
        centralManager.connect(peripheral, options: nil)
    }
    
    func disconnect() {
        guard let peripheral = connectedPeripheral else {
            print("No peripheral connected to disconnect.")
            return
        }
        print("Disconnecting from: \(peripheral.name ?? "Unknown")")
        centralManager.cancelPeripheralConnection(peripheral)
    }
    
    func getDiscoveredPeripherals() -> [CBPeripheral] {
        return discoveredPeripherals
    }
    
    // Placeholder for sending messages (requires characteristic discovery first)
    func sendMessage(_ message: String) {
        guard let characteristic = targetCharacteristic,
              let peripheral = connectedPeripheral else {
            print("Cannot send message: Not connected or characteristic not found.")
            return
        }
        
        guard let data = message.data(using: .utf8) else {
            print("Failed to convert message to data.")
            return
        }
        
        // Write with response (use .withoutResponse if you don't need confirmation)
        peripheral.writeValue(data, for: characteristic, type: .withResponse)
        print("Sent message: \(message)")
    }
}

// MARK: - CBCentralManagerDelegate
extension BluetoothManager: CBCentralManagerDelegate {
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        print("Bluetooth state updated: \(central.state.rawValue)")
        onBluetoothStateUpdate?(central.state)
        
        // Optional: Auto-start scanning when powered on
        // if central.state == .poweredOn {
        //     startScanning()
        // }
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        print("Discovered: \(peripheral.name ?? "Unknown") (RSSI: \(RSSI))")
        
        if !discoveredPeripherals.contains(where: { $0.identifier == peripheral.identifier }) {
            discoveredPeripherals.append(peripheral)
        }
        
        // Notify external handler
        onPeripheralDiscovered?(peripheral, advertisementData, RSSI)
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        print("Connected to: \(peripheral.name ?? "Unknown")")
        connectedPeripheral = peripheral
        peripheral.delegate = self // Set delegate to receive peripheral events
        
        // Start discovering services after connecting
        print("Discovering services...")
        peripheral.discoverServices([YOUR_SERVICE_UUID])
        
        // Notify external handler
        onConnectionAttemptFinished?(true, peripheral, nil)
    }
    
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        let errorMessage = error?.localizedDescription ?? "Unknown error"
        print("Failed to connect to: \(peripheral.name ?? "Unknown"). Error: \(errorMessage)")
        
        // Notify external handler
        onConnectionAttemptFinished?(false, peripheral, error)
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        let errorMessage = error?.localizedDescription ?? "No error"
        print("Disconnected from: \(peripheral.name ?? "Unknown"). Error: \(errorMessage)")
        
        if connectedPeripheral?.identifier == peripheral.identifier {
            connectedPeripheral = nil
            targetCharacteristic = nil
        }
        
        // You might trigger a rescan or notify UI here
    }
}

// MARK: - CBPeripheralDelegate
extension BluetoothManager: CBPeripheralDelegate {
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
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
            if service.uuid == YOUR_SERVICE_UUID {
                print("    -> Found target service. Discovering characteristics...")
                // Discover characteristics for the target service
                peripheral.discoverCharacteristics([YOUR_CHARACTERISTIC_UUID], for: service)
            }
        }
        onServicesDiscovered?(.success(()))
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
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
             if characteristic.uuid == YOUR_CHARACTERISTIC_UUID {
                 print("    -> Found target characteristic.")
                 targetCharacteristic = characteristic
                 
                 // If the characteristic supports notifications, enable them
                 if characteristic.properties.contains(.notify) {
                     print("    -> Enabling notifications for this characteristic.")
                     peripheral.setNotifyValue(true, for: characteristic)
                 } else {
                     print("    -> Characteristic does not support notifications.")
                 }
                 
                 // Notify that we are ready for messaging (characteristic found)
                 onCharacteristicsDiscovered?(.success(()))
                 return // Assume we only care about this one characteristic for now
             }
         }
         // If we get here, the target characteristic wasn't found
         let notFoundError = NSError(domain: "BluetoothManager", code: -4, userInfo: [NSLocalizedDescriptionKey: "Target characteristic not found"])
         print("Error: \(notFoundError.localizedDescription)")
         onCharacteristicsDiscovered?(.failure(notFoundError))
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        if let error = error {
            print("Error updating value for characteristic \(characteristic.uuid): \(error)")
            return
        }
        
        guard let data = characteristic.value else {
            print("Received update with no data for characteristic \(characteristic.uuid)")
            return
        }
        
        print("Received data update on characteristic \(characteristic.uuid).")
        // Notify external handler with the received data
        onMessageReceived?(data)
    }
    
    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        if let error = error {
            print("Error writing to characteristic \(characteristic.uuid): \(error)")
        } else {
            print("Successfully wrote to characteristic \(characteristic.uuid).")
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?) {
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
