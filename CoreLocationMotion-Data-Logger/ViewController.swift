//
//  ViewController.swift
//  CoreLocationMotion-Data-Logger
//
//  Created by kimpyojin on 29/05/2019.
//  Copyright © 2019 Pyojin Kim. All rights reserved.
//

import UIKit
import CoreLocation
import CoreMotion
import os.log
import AudioToolbox
import Foundation

extension Date {
    func currentTimeMillis() -> Int64 {
        Int64(timeIntervalSince1970 * 1000)
    }
}

extension DispatchQueue {
    static func background(delay: Double = 0.0, background: (() -> Void)? = nil, completion: (() -> Void)? = nil) {
        DispatchQueue.global(qos: .background).async {
            background?()
            if let completion = completion {
                DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: {
                    completion()
                })
            }
        }
    }
}

@available(iOS 13.0, *)
private var hapticManager: HapticManager?

@available(iOS 13.0, *)
class ViewController: UIViewController, CLLocationManagerDelegate {
    // cellphone screen UI outlet objects
    @IBOutlet weak var startStopButton: UIButton!
    @IBOutlet weak var hapticsButton: UIButton!
    @IBOutlet weak var statusLabel: UILabel!

    var hapticManager = HapticManager()

    let sampleFrequency: TimeInterval = 200
    let gravity: Double = 9.81
    let defaultValue: Double = 0.0
    var isRecording: Bool = false

    // various motion managers and queue instances
    let locationManager = CLLocationManager()
    let motionManager = CMMotionManager()
    let altimeter = CMAltimeter()
    let customQueue: DispatchQueue = DispatchQueue(label: "saveDataQueue")

    // variables for measuring time in iOS clock
    var recordingTimer: Timer = Timer()
    var batteryLevelTimer: Timer = Timer()
    var secondCounter: Int64 = 0 {
        didSet {
            statusLabel.text = interfaceIntTime(second: secondCounter)
        }
    }
    let mulSecondToNanoSecond: Double = 1000000000
    let jimsSecond: Int = 1000

    // text file input & output
    var sensorData = SensorData()
    // TODO: Send data to firestore instead of file at end
    // TODO: Add ability to record real or not
    // TODO: Add ability to record holo or not
    // TODO: Add ability to record session automatically (set a time and have it run that long
    // TODO: Log phone meta
    var i: Int = 1
    var sum: Int = 0

    override func viewDidLoad() {
        super.viewDidLoad()
        // default device setting
        statusLabel.text = "Ready"
        UIDevice.current.isBatteryMonitoringEnabled = true
        // define Core Location manager setting
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
        locationManager.requestAlwaysAuthorization()
        locationManager.startUpdatingLocation()
        // define Core Motion manager setting
        customQueue.async {
            self.startIMUUpdate()
            self.startAltimeterUpdate()
            self.startBatteryLevelUpdate()
        }
    }

    func craptics() {
        while i < 200 {
            for _ in 1...7 {
                hapticManager?.playSlice()
                usleep(2000);
            }
            i += 1
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        locationManager.stopUpdatingLocation()
        customQueue.sync {
            stopIMUUpdate()
        }
        altimeter.stopRelativeAltitudeUpdates()
    }

    // when the Start/Stop button is pressed
    @IBAction func startStopButtonPressed(_ sender: UIButton) {
        if (isRecording == false) {
            // start GPS/IMU data recording
            customQueue.async {
                DispatchQueue.main.async {
                    // reset timer
                    self.secondCounter = 0
                    self.recordingTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true, block: { (Timer) -> Void in
                        self.secondCounter += 1
                    })
                    // update UI
                    self.startStopButton.setTitle("Stop", for: .normal)
                    // make sure the screen won't lock
                    UIApplication.shared.isIdleTimerDisabled = true
                }
                self.isRecording = true
                //Jim's amazing non-haptic haptics
                self.craptics()
            }
        } else {
            // stop recording and share the recorded text file
            if (recordingTimer.isValid) {
                recordingTimer.invalidate()
            }
            if (batteryLevelTimer.isValid) {
                batteryLevelTimer.invalidate()
            }
            customQueue.async {
                self.isRecording = false
                // TODO: Convert sensorData struct to dict
                self.sensorData.total_time = Int(self.secondCounter)
                let sensorDataUpload = self.sensorData.toDict
                print("struff")
                // TODO: Send dict to firestore
            }
            startStopButton.setTitle("Start", for: .normal)
            statusLabel.text = "Ready"
            // resume screen lock
            UIApplication.shared.isIdleTimerDisabled = false
        }
    }

    // define startUpdatingLocation() function
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        // optional binding for safety
        if let latestLocation = manager.location {
            let timestamp = latestLocation.timestamp.timeIntervalSince1970 * mulSecondToNanoSecond
            //let timestamp = Date().timeIntervalSince1970 * self.mulSecondToNanoSecond
            let latitude = latestLocation.coordinate.latitude
            let longitude = latestLocation.coordinate.longitude
            let horizontalAccuracy = latestLocation.horizontalAccuracy
            let altitude = latestLocation.altitude
            let verticalAccuracy = latestLocation.verticalAccuracy
            var buildingFloor = -9
            if let temp = latestLocation.floor {
                buildingFloor = temp.level
            }
            // Note: GPS data queue
            customQueue.async {
                if (self.isRecording) {
                    // store gps data
                    self.sensorData.gps.timestamps.append(timestamp)
                    self.sensorData.gps.lat.append(latitude)
                    self.sensorData.gps.long.append(longitude)
                    self.sensorData.gps.horizontal_acc.append(horizontalAccuracy)
                    self.sensorData.gps.altitude.append(altitude)
                    self.sensorData.gps.vertical_acc.append(verticalAccuracy)
                    self.sensorData.gps.building_floor.append(buildingFloor)
                }
            }
        }
    }

    // define didFailWithError function
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("GPS Error => \(error.localizedDescription)")
    }

    // define startIMUUpdate() function
    private func startIMUUpdate() {
        // define IMU update interval up to 200 Hz (in real, iOS can only support up to 100 Hz)
        motionManager.deviceMotionUpdateInterval = 1.0 / sampleFrequency
        motionManager.showsDeviceMovementDisplay = true
        motionManager.accelerometerUpdateInterval = 1.0 / sampleFrequency
        motionManager.gyroUpdateInterval = 1.0 / sampleFrequency
        motionManager.magnetometerUpdateInterval = 1.0 / sampleFrequency
        // 1) update device motion
        if (!motionManager.isDeviceMotionActive) {
            motionManager.startDeviceMotionUpdates(using: .xMagneticNorthZVertical, to: OperationQueue.main) { (motion: CMDeviceMotion?, error: Error?) in
                // optional binding for safety
                if let deviceMotion = motion {
                    //let timestamp = Date().timeIntervalSince1970 * self.mulSecondToNanoSecond
                    // let timestamp = deviceMotion.timestamp * self.mulSecondToNanoSecond
                    let timestamp = Date().timeIntervalSince1970 * self.mulSecondToNanoSecond

                    let deviceOrientationQx = deviceMotion.attitude.quaternion.x
                    let deviceOrientationQy = deviceMotion.attitude.quaternion.y
                    let deviceOrientationQz = deviceMotion.attitude.quaternion.z
                    let deviceOrientationQw = deviceMotion.attitude.quaternion.w

                    let processedGyroDataX = deviceMotion.rotationRate.x
                    let processedGyroDataY = deviceMotion.rotationRate.y
                    let processedGyroDataZ = deviceMotion.rotationRate.z

                    let gravityGx = deviceMotion.gravity.x * self.gravity
                    let gravityGy = deviceMotion.gravity.y * self.gravity
                    let gravityGz = deviceMotion.gravity.z * self.gravity

                    let userAccelDataX = deviceMotion.userAcceleration.x * self.gravity
                    let userAccelDataY = deviceMotion.userAcceleration.y * self.gravity
                    let userAccelDataZ = deviceMotion.userAcceleration.z * self.gravity

                    let magneticFieldX = deviceMotion.magneticField.field.x
                    let magneticFieldY = deviceMotion.magneticField.field.y
                    let magneticFieldZ = deviceMotion.magneticField.field.z

                    let deviceHeadingAngle = deviceMotion.heading

                    // custom queue to save IMU text data
                    self.customQueue.async {
                        if (self.isRecording) {
                            // store attitude data
                            self.sensorData.attitude.timestamps.append(timestamp)
                            self.sensorData.attitude.x.append(deviceOrientationQx)
                            self.sensorData.attitude.y.append(deviceOrientationQy)
                            self.sensorData.attitude.z.append(deviceOrientationQz)
                            self.sensorData.attitude.w.append(deviceOrientationQw)
                            // store gyroscope data
                            self.sensorData.gyroscope.timestamps.append(timestamp)
                            self.sensorData.gyroscope.x.append(processedGyroDataX)
                            self.sensorData.gyroscope.y.append(processedGyroDataY)
                            self.sensorData.gyroscope.z.append(processedGyroDataZ)
                            // store gravity vector
                            self.sensorData.gravity.timestamps.append(timestamp)
                            self.sensorData.gravity.x.append(gravityGx)
                            self.sensorData.gravity.y.append(gravityGy)
                            self.sensorData.gravity.z.append(gravityGz)
                            // store unser-generated acceleration vector w/ out gravity (lin_acc)
                            self.sensorData.line_acc.timestamps.append(timestamp)
                            self.sensorData.line_acc.x.append(userAccelDataX)
                            self.sensorData.line_acc.y.append(userAccelDataY)
                            self.sensorData.line_acc.z.append(userAccelDataZ)
                            // store magnetic field vector
                            self.sensorData.magnet.timestamps.append(timestamp)
                            self.sensorData.magnet.x.append(magneticFieldX)
                            self.sensorData.magnet.y.append(magneticFieldY)
                            self.sensorData.magnet.z.append(magneticFieldZ)
                            // store the heading angle (degrees) relative to the reference frame
                            self.sensorData.heading.timestamps.append(timestamp)
                            self.sensorData.heading.value.append(deviceHeadingAngle)
                        }
                    }
                }
            }
        }
        // 2) update raw acceleration value
        if (!motionManager.isAccelerometerActive) {
            motionManager.startAccelerometerUpdates(to: OperationQueue.main) { (motion: CMAccelerometerData?, error: Error?) in
                // optional binding for safety
                if let accelerometerData = motion {
                    let timestamp = Date().timeIntervalSince1970 * self.mulSecondToNanoSecond
                    //let timestamp = accelerometerData.timestamp * self.mulSecondToNanoSecond
                    let rawAccelDataX = accelerometerData.acceleration.x * self.gravity
                    let rawAccelDataY = accelerometerData.acceleration.y * self.gravity
                    let rawAccelDataZ = accelerometerData.acceleration.z * self.gravity
                    // custom queue to save IMU text data
                    self.customQueue.async {
                        if (self.isRecording) {
                            // store raw acceleration data
                            self.sensorData.acc.timestamps.append(timestamp)
                            self.sensorData.acc.x.append(rawAccelDataX)
                            self.sensorData.acc.y.append(rawAccelDataY)
                            self.sensorData.acc.z.append(rawAccelDataZ)
                        }
                    }
                }
            }
        }
        // 3) update raw gyroscope value
        if (!motionManager.isGyroActive) {
            motionManager.startGyroUpdates(to: OperationQueue.main) { (motion: CMGyroData?, error: Error?) in
                // optional binding for safety
                if let gyroData = motion {
                    let timestamp = Date().timeIntervalSince1970 * self.mulSecondToNanoSecond
                    //let timestamp = gyroData.timestamp * self.mulSecondToNanoSecond
                    //let timestamp = Date().timeIntervalSince1970 * self.mulSecondToNanoSecond
                    let rawGyroDataX = gyroData.rotationRate.x
                    let rawGyroDataY = gyroData.rotationRate.y
                    let rawGyroDataZ = gyroData.rotationRate.z
                    // custom queue to save IMU text data
                    self.customQueue.async {
                        if (self.isRecording) {
                            // store raw (uncalibrated) gyroscope data
                            self.sensorData.gyroscope_uncal.timestamps.append(timestamp)
                            self.sensorData.gyroscope_uncal.x.append(rawGyroDataX)
                            self.sensorData.gyroscope_uncal.y.append(rawGyroDataY)
                            self.sensorData.gyroscope_uncal.z.append(rawGyroDataZ)
                        }
                    }
                }
            }
        }

        // 4) update raw magnetometer data
        if (!motionManager.isMagnetometerActive) {
            motionManager.startMagnetometerUpdates(to: OperationQueue.main) { (motion: CMMagnetometerData?, error: Error?) in

                // optional binding for safety
                if let magnetometerData = motion {
                    let timestamp = Date().timeIntervalSince1970 * self.mulSecondToNanoSecond
                    //let timestamp = magnetometerData.timestamp * self.mulSecondToNanoSecond
                    let rawMagnetDataX = magnetometerData.magneticField.x
                    let rawMagnetDataY = magnetometerData.magneticField.y
                    let rawMagnetDataZ = magnetometerData.magneticField.z

                    // custom queue to save IMU text data
                    self.customQueue.async {
                        if (self.isRecording) {
                            // store raw (uncalibrated) magnetometer data
                            self.sensorData.magnet_uncal.timestamps.append(timestamp)
                            self.sensorData.magnet_uncal.x.append(rawMagnetDataX)
                            self.sensorData.magnet_uncal.y.append(rawMagnetDataY)
                            self.sensorData.magnet_uncal.z.append(rawMagnetDataZ)
                        }
                    }
                }
            }
        }
    }
    // define startAltimeterUpdate() function
    private func startAltimeterUpdate() {
        // check barometric sensor information are available
        if (CMAltimeter.isRelativeAltitudeAvailable()) {
            altimeter.startRelativeAltitudeUpdates(to: OperationQueue.main) { (motion: CMAltitudeData?, error: Error?) in
                // optional binding for safety
                if let barometerData = motion {
                    //let timestamp = barometerData.timestamp * self.mulSecondToNanoSecond
                    let timestamp = Date().timeIntervalSince1970 * self.mulSecondToNanoSecond
                    let pressure = barometerData.pressure.doubleValue
                    // custom queue to save barometric text data
                    self.customQueue.async {
                        if (self.isRecording) {
                            // store recorded pressure (in kilopascals)
                            self.sensorData.pressure.timestamps.append(timestamp)
                            self.sensorData.pressure.value.append(pressure)
                        }
                    }
                }
            }
        }
    }

    // define startBatteryLevelUpdate() function
    private func startBatteryLevelUpdate() {
        DispatchQueue.main.async {
            self.batteryLevelTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true, block: { (Timer) -> Void in
                let timestamp = Date().timeIntervalSince1970 * self.mulSecondToNanoSecond
                let batteryLevel = UIDevice.current.batteryLevel

                self.customQueue.async {
                    if (self.isRecording) {
                        // store the battery charge level for the device
                        self.sensorData.battery.timestamps.append(timestamp)
                        self.sensorData.battery.value.append(Double(batteryLevel))
                    }
                }
            })
        }
    }

    private func stopIMUUpdate() {
        if (motionManager.isDeviceMotionActive) {
            motionManager.stopDeviceMotionUpdates()
        }
        if (motionManager.isAccelerometerActive) {
            motionManager.stopAccelerometerUpdates()
        }
        if (motionManager.isGyroActive) {
            motionManager.stopGyroUpdates()
        }
        if (motionManager.isMagnetometerActive) {
            motionManager.stopMagnetometerUpdates()
        }
    }

    // some useful functions
    private func errorMsg(msg: String) {
        DispatchQueue.main.async {
            let fileAlert = UIAlertController(title: "CoreLocationMotion-Data-Logger", message: msg, preferredStyle: .alert)
            fileAlert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
            self.present(fileAlert, animated: true, completion: nil)
        }
    }
}
