import Foundation

struct SensorData {
    var start_time: Double = 0
    var end_time: Double = 0
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
        return [
            "start_time": start_time,
            "acc": line_acc.toDict
        ]
    }
}

struct ScalarSensorData {
    var timestamps: [Double] = []
    var value: [Double] = []
}

struct TripletSensorData {
    var timestamps: [Double] = []
    var x: [Double] = []
    var y: [Double] = []
    var z: [Double] = []

    var toDict: [String: Any] {
        return [
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
}

struct GPS {
    var timestamps: [Double] = []
    var lat: [Double] = []
    var long: [Double] = []
    var horizontal_acc: [Double] = []
    var altitude: [Double] = []
    var building_floor: [Int] = []
    var vertical_acc: [Double] = []
}
