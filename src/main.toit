import ble
import bytes

/**
ESC Commands...
*/
CUT ::= #[0x1d, 0x56, 0x00]


find-device-for-service central /ble.Central --service/ble.BleUuid  -> ble.RemoteScannedDevice:
  scan-duration_ := Duration --s=3
  central.scan --duration=scan-duration_ : | device /ble.RemoteScannedDevice|
    if device.data.service-classes.contains (ble.BleUuid "18f0"):
      return device
  throw "Device not found"

get-write-characteristic-from-peripheral peripheral /ble.RemoteDevice -> ble.RemoteCharacteristic:
  peripheral.discover-services
  peripheral.discovered-services.do: |service /ble.RemoteService |
    service.discover-characteristics
    service.discovered-characteristics.do: |characteristic /ble.RemoteCharacteristic |
      if service.uuid == (ble.BleUuid "18f0") and characteristic.properties == 12:
        return characteristic
  throw "correct characteristic not found"

list-everything-for-peripheral peripheral /ble.RemoteDevice:
  services := peripheral.discover-services
  peripheral.discovered-services.do: |service /ble.RemoteService|
    service.discover-characteristics
    service.discovered-characteristics.do: | characteristic /ble.RemoteCharacteristic |
      characteristic.discover-descriptors
      print "$service.uuid/$characteristic.uuid properties: $characteristic.properties" 


main:
  adapter_ := ble.Adapter 
  central := ble.Central adapter_
  device-to-connect /ble.RemoteScannedDevice := find-device-for-service central --service=(ble.BleUuid "18f0")
  print "Device to connect: $device-to-connect.data.service-classes"
  peripheral /ble.RemoteDevice := central.connect device-to-connect.address

  write-characteristic /ble.RemoteCharacteristic := get-write-characteristic-from-peripheral peripheral
  print "$write-characteristic.properties"
  write-characteristic.write #[0x1b, 0x4A, 0x01]/// move lines
  write-characteristic.write "Hello Nancy!\nThis is a secret message written just for you.\nYou are loved :)".to-byte-array
  write-characteristic.write #[0x1b, 0x4A, 0x01]/// move lines
  write-characteristic.write CUT
