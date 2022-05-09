//
//  ViewController.swift
//  test
//
//  Created by Justin Kwok Lam CHAN on 4/4/21.
//

import Charts
import UIKit
import CoreMotion
import simd

class ViewController: UIViewController, ChartViewDelegate {
    
    @IBOutlet weak var lineChartView: LineChartView!
    @IBOutlet weak var startButton: UIButton!
    @IBOutlet weak var stopButton: UIButton!
    @IBOutlet weak var label: UILabel!
    
    var ts: Double = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        self.lineChartView.delegate = self
        
        let set_a: LineChartDataSet = LineChartDataSet(entries: [ChartDataEntry](), label: "accel tilt")
        set_a.drawCirclesEnabled = false
        set_a.setColor(UIColor.blue)
        
        let set_b: LineChartDataSet = LineChartDataSet(entries: [ChartDataEntry](), label: "gyro tilt")
        set_b.drawCirclesEnabled = false
        set_b.setColor(UIColor.red)
        
        let set_c: LineChartDataSet = LineChartDataSet(entries: [ChartDataEntry](), label: "z")
        set_c.drawCirclesEnabled = false
        set_c.setColor(UIColor.green)
        self.lineChartView.data = LineChartData(dataSets: [set_a,set_b,set_c])
    }
    
    @IBAction func startSensors(_ sender: Any) {
        ts=NSDate().timeIntervalSince1970
        label.text=String(format: "%f", ts)
        startAccelerometers()
        startGyros()
        startButton.isEnabled = false
        stopButton.isEnabled = true
    }
    
    @IBAction func stopSensors(_ sender: Any) {
        stopAccels()
        stopGyros()
        startButton.isEnabled = true
        stopButton.isEnabled = false
    }
    
    let motion = CMMotionManager()
    var counter:Double = 0
    var counterM:Double = 0
    
    var timer_accel:Timer?
    var accel_file_url:URL?
    var accel_fileHandle:FileHandle?
    var a_tilt:Double = 0 // accelerometer tilt
    
    // vars for comp filter
    var ax_pitch:Double = 0
    var ay_roll:Double = 0
    var az_yaw:Double = 0
    
    var timer_gyro:Timer?
    var gyro_file_url:URL?
    var gyro_fileHandle:FileHandle?
    var xsum:Double = 0
    var ysum:Double = 0
    var zsum:Double = 0
    var g_tilt:Double = 0 // gyroscope tilt
    
    // vars for comp filter
    var x_filter:Double = 0
    var y_filter:Double = 0
    var z_filter:Double = 0
    
    var xfsum:Double = 0
    var yfsum:Double = 0
    var zfsum:Double = 0
    
    var timer_mag:Timer?
    var mag_file_url:URL?
    var mag_fileHandle:FileHandle?
    
    let xrange:Double = 500
    
    func startAccelerometers() {
       // Make sure the accelerometer hardware is available.
       if self.motion.isAccelerometerAvailable {
        // sampling rate can usually go up to at least 100 hz
        // if you set it beyond hardware capabilities, phone will use max rate
          self.motion.accelerometerUpdateInterval = 1.0 / 60.0  // 60 Hz
          self.motion.startAccelerometerUpdates()
        
        // create the data file we want to write to
        // initialize file with header line
        do {
            // get timestamp in epoch time
            let file = "accel_file_\(ts).txt"
            if let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
                accel_file_url = dir.appendingPathComponent(file)
            }
            
            // write first line of file
            try "ts,x,y,z\n".write(to: accel_file_url!, atomically: true, encoding: String.Encoding.utf8)

            accel_fileHandle = try FileHandle(forWritingTo: accel_file_url!)
            accel_fileHandle!.seekToEndOfFile()
        } catch {
            print("Error writing to file \(error)")
        }
        
          // Configure a timer to fetch the data.
          self.timer_accel = Timer(fire: Date(), interval: (1.0/60.0),
                                   repeats: true, block: { [self] (timer) in
             // Get the accelerometer data.
             if let data = self.motion.accelerometerData {
                 let x = data.acceleration.x * 9.81
                 let y = data.acceleration.y * 9.81
                 let z = data.acceleration.z * 9.81
                 
                 let R = sqrt(x*x + y*y + z*z)
                 
                 a_tilt =  acos(-z/R) * (180/Double.pi)
                
                 ax_pitch = atan(-x/sqrt(y*y + z*z)) * (180/Double.pi)
                 ay_roll = atan(y/z) * (180/Double.pi)


                let timestamp = NSDate().timeIntervalSince1970
                let text = "\(timestamp), \(x), \(y), \(z)\n"
                print ("A: \(text)")
                
             }
          })

          // Add the timer to the current run loop.
        RunLoop.current.add(self.timer_accel!, forMode: RunLoop.Mode.default)
       }
    }
    
    func startGyros() {
       if motion.isGyroAvailable {
          self.motion.gyroUpdateInterval = 1.0 / 60.0
          self.motion.startGyroUpdates()
        
        do {
            let file = "tilt_file_\(ts).txt"
            if let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
                gyro_file_url = dir.appendingPathComponent(file)
            }
            
            try "ts,ta,tg,tc\n".write(to: gyro_file_url!, atomically: true, encoding: String.Encoding.utf8)

            gyro_fileHandle = try FileHandle(forWritingTo: gyro_file_url!)
            gyro_fileHandle!.seekToEndOfFile()
        } catch {
            print("Error writing to file \(error)")
        }
        
          // Configure a timer to fetch the accelerometer data.
          self.timer_gyro = Timer(fire: Date(), interval: (1.0/60.0),
                 repeats: true, block: { (timer) in
             // Get the gyro data.
             if let data = self.motion.gyroData {
                let x = data.rotationRate.x
                let y = data.rotationRate.y
                let z = data.rotationRate.z
                 
                // get gyroscope angles in degrees
                let x_deg = x * (1.0/60.0) * (180/Double.pi)
                let y_deg = y * (1.0/60.0) * (180/Double.pi)
                let z_deg = z * (1.0/60.0) * (180/Double.pi)
                 
                // intergrate gyroscope angles
                self.xsum += x_deg
                self.ysum += y_deg
                self.zsum += z_deg
                 
                // calculate tilt from gyroscope
                self.g_tilt = sqrt(self.xsum*self.xsum + self.ysum*self.ysum)
                
                // apply comp filter to x, y, and z angles
                self.xfsum = 0.98 * (self.xfsum + x_deg) + 0.02 * (self.ax_pitch)
                self.yfsum = 0.98 * (self.yfsum - y_deg) + 0.02 * (self.ay_roll)
                                  
                 
                let comp_tilt = sqrt(self.xfsum*self.xfsum + self.yfsum*self.yfsum)
                 
                
                let timestamp = NSDate().timeIntervalSince1970
                // write tilt data to gyroscope file
                let text = "\(timestamp), \(self.a_tilt), \(self.g_tilt), \(comp_tilt)\n"
                print ("G: \(text)")
                
                self.gyro_fileHandle!.write(text.data(using: .utf8)!)
                
                 self.lineChartView.data?.addEntry(ChartDataEntry(x: Double(self.counter), y: self.a_tilt), dataSetIndex: 0)
                 self.lineChartView.data?.addEntry(ChartDataEntry(x: Double(self.counter), y: self.g_tilt), dataSetIndex: 1)
                 self.lineChartView.data?.addEntry(ChartDataEntry(x: Double(self.counter), y: comp_tilt), dataSetIndex: 2)
                 
                 // refreshes the data in the graph
                 self.lineChartView.notifyDataSetChanged()
                   
                 self.counter = self.counter+1
                 
                 // needs to come up after notifyDataSetChanged()
                 if self.counter < self.xrange {
                     self.lineChartView.setVisibleXRange(minXRange: 0, maxXRange: self.xrange)
                 }
                 else {
                     self.lineChartView.setVisibleXRange(minXRange: self.counter, maxXRange: self.counter+self.xrange)
                 }
             }
          })

          // Add the timer to the current run loop.
          RunLoop.current.add(self.timer_gyro!, forMode: RunLoop.Mode.default)
       }
    }
    
    
    func stopAccels() {
       if self.timer_accel != nil {
          self.timer_accel?.invalidate()
          self.timer_accel = nil

          self.motion.stopAccelerometerUpdates()
        
           accel_fileHandle!.closeFile()
       }
    }
    
    func stopGyros() {
       if self.timer_gyro != nil {
          self.timer_gyro?.invalidate()
          self.timer_gyro = nil

          self.motion.stopGyroUpdates()
          
           gyro_fileHandle!.closeFile()
       }
    }
    
}

