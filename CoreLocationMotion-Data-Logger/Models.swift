import Foundation

struct SensorData {
    var total_time: Int = 0
    var is_real: Bool = true
    var is_holo: Bool = false
    var acc: TripletSensorData = TripletSensorData()
    var battery: ScalarSensorData = ScalarSensorData()
    var attitude: QuaternionTripletSensorData = QuaternionTripletSensorData()
    var gps: GPS = GPS()
    var gravity: TripletSensorData = TripletSensorData()
    var gyroscope: TripletSensorData = TripletSensorData()
    var gyroscope_uncal: TripletSensorData = TripletSensorData()
    var heading: ScalarSensorData = ScalarSensorData()
    var height: ScalarSensorData = ScalarSensorData()
    var line_acc: TripletSensorData = TripletSensorData()
    var magnet: TripletSensorData = TripletSensorData()
    var magnet_uncal: TripletSensorData = TripletSensorData()
    var pressure: ScalarSensorData = ScalarSensorData()
    
    var toDict: [String: Any] {
        [
            "total_time": total_time,
            "is_real": is_real,
            "is_holo": is_holo,
            "acc": line_acc.toDict,
            "battery": battery.toDict,
            "attitude": attitude.toDict,
            "gps": gps.toDict,
            "gravity": gravity.toDict,
            "gyroscope": gyroscope.toDict,
            "gyroscope_uncal": gyroscope_uncal.toDict,
            "heading": heading.toDict,
            "height": height.toDict,
            "line_acc": line_acc.toDict,
            "magnet": magnet.toDict,
            "magnet_uncal": magnet_uncal.toDict,
            "pressure": pressure.toDict
        ]
    }
}

struct ScalarSensorData {
    var timestamps: [Double] = []
    var value: [Double] = []

    var toDict: [String: Any] {
        [
            "timestamps": timestamps,
            "value": value
        ]
    }
}

struct TripletSensorData {
    var timestamps: [Double] = []
    var x: [Double] = []
    var y: [Double] = []
    var z: [Double] = []

    var toDict: [String: Any] {
        [
            "timestamps": timestamps,
            "x": x,
            "y": y,
            "z": z
        ]
    }
}

struct QuaternionTripletSensorData {
    var timestamps: [Double] = []
    var x: [Double] = []
    var y: [Double] = []
    var z: [Double] = []
    var w: [Double] = []

    var toDict: [String: Any] {
        [
            "timestamps": timestamps,
            "x": x,
            "y": y,
            "z": z,
            "w": w
        ]
    }
}

struct GPS {
    var timestamps: [Double] = []
    var lat: [Double] = []
    var long: [Double] = []
    var horizontal_acc: [Double] = []
    var altitude: [Double] = []
    var building_floor: [Int] = []
    var vertical_acc: [Double] = []

    var toDict: [String: Any] {
        [
            "timestamps": timestamps,
            "lat": lat,
            "long": long,
            "horizontal_acc": horizontal_acc,
            "altitude": altitude,
            "building_floor": building_floor,
            "vertical_acc": vertical_acc
        ]
    }
}
