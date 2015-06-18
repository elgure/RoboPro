require 'socket'
require 'matrix'
require 'serialport'

def init_server
	server = TCPServer.new 3601
  puts "[Server launched]"
	loop do
		client = server.accept
		puts "[New socket connected]"

		while line = client.gets
			line.delete! "\n"
			values = line.split ","
			sendMessageToArduino(values)
		end
    puts "[Socket disconnected]"
	end	
end

def init_serial
	if (@serial == nil)
		port = "/dev/tty.usbmodem1421"
		@serial = SerialPort.new(port, 115200, 8, 1, SerialPort::NONE)
    puts "[Init Serial on #{port}]"
	end
end

def close_serial
	@serial.close
end

def sendMessageToArduino (params)
	if (params[0] == 's')
		#@serial.puts "s"
		puts "[SEND MOTOR MESSAGE]: s"
	else
		pwm1 = params[0]
		pwm2 = params[1]
		pwm3 = params[2]

		puts "[Send Serial Message]: r #{pwm1},#{pwm2},#{pwm3},"
		#@serial.puts "r #{pwm1},#{pwm2},#{pwm3},"
	end

	# angle = params[0].to_f
	# x = params[1].to_f
	# y = params[2].to_f

 	#pwm = compute_pwm(x, y)
 	#pwm = verify_pwn(angle.to_f, pwm, x, y)
  	
  	#puts "[Send Serial Message]: r #{pwm.element(0, 0)},#{pwm.element(0, 1)},#{pwm.element(0, 2)},"  
	#@serial.puts "r #{pwm.element(0, 0)},#{pwm.element(0, 1)},#{pwm.element(0, 2)},"

	
	
end

def verify_pwn(angle, pwm, x, y)
	#bug to fix on 0-180º vertical ligne
	#bug description: when you cross that line with the buttom the server crash 
	#Center
	if y < 0.1 && y > -0.1 && x < 0.1 && x > -0.1 
	        puts "[Center]"
	        return Matrix[[0,0,0]];        
	#General                                                                                                               
    elsif ( angle > 5 && angle < 55 ) || ( angle > 65 && angle < 115 )         #0º to 120º
        return Matrix[[ pwm.element(0,0).floor, 0, -pwm.element(2,0).floor ]];
    elsif ( angle > 125 && angle < 175 ) || ( angle > 185 && angle < 235 )     #120º to 240º
        return Matrix[[ 0, pwm.element(1,0).floor , pwm.element(2,0).floor ]]; 
    elsif ( angle > 245 && angle < 295 ) || ( angle > 305 && angle < 355 )     #240º 360º
        return Matrix[[ pwm.element(0,0).floor, pwm.element(1,0).floor, 0 ]];
	#Exceptions
	else                                                                       
	    if y > 0
	        if angle >= 355 || angle <= 5
	        	puts "[Forward 0º]"  
	            return Matrix[[ 0, -pwm.element(1,0).floor, pwm.element(1.0).floor ]];     #Forward (M1)
	        elsif angle >= 115 && angle <= 125
	        	puts "[Forward 120º]" 
	            return Matrix[[ -pwm.element(0,0).floor, pwm.element(0,0).floor, 0 ]];     #Forward 120º (M3)
	        elsif angle >= 235 && angle <= 245
	        	puts "[Forward 240º]" 
	            return Matrix[[pwm.element(0,0).floor, 0, -pwm.element(0,0).floor ]];      #Forward 240º (M2)
	    	end
	    elsif y < 0
	        if angle >= 175 && angle <= 185
	        	puts "[Backward 180º]"    
	            return Matrix[[ 0, pwm.element(1,0).floor, -pwm.element(1.0).floor ]];     #Backward (M1)
	        elsif angle >= 295 && angle <= 305
	        	puts "[Backward 300º]" 
	            return Matrix[[ pwm.element(0,0).floor, -pwm.element(0,0).floor, 0 ]];     #Backward 300º (M3)
	        elsif angle >= 55 && angle <= 65
	        	puts "[Backward 60º]" 
	            return Matrix[[pwm.element(0,0).floor, 0, -pwm.element(0,0).floor ]];      #Backward 60º (M3)
			end
		else
			puts "[Error]"
			return Matrix[[0, 0, 0]];
		end
	end
	# #Old implementation
	# if angle >= 0 && angle < 120
	# 	return  Matrix[[pwm.element(0,0).floor, 0, -pwm.element(2,0).floor]]; 	
	# elsif angle > 120 && angle < 240
	# 	return  Matrix[[0,pwm.element(1,0).floor , pwm.element(2,0).floor]]; 
	# elsif angle > 240 && angle < 360
	# 	return Matrix[[pwm.element(0,0).floor, pwm.element(1,0).floor, 0]];
	# else 
	# 	puts "[Reset]"
	# 	return Matrix[[0, 0, 0]];
	# end
end

def compute_pwm(x, y)
	
	#Const.
	l = 15         											#Distance between center of gravity and center of tires
	toRad = 57.2957795  										#deg to rad divader
	max_Value = 200     										#Max Value of PWM

	#Vmax Matrix Elements 
	#Vmax = [vxmax  vymax vtmax] (transpose)
    vxmax = 266.66666670347945
    vymax = 230.9401076439695
	#vtmax = 13.333333333333336  #12.269938650306749  #ATM unused constant but while be use later on.

	#Ce Matrix Elements
	#Ce = [e0 e1 e2] (transpose)
	e0 = 0.428571429   											#Avoid PWM to went over 200
	e1 = 0.375													
	e2 = 0.375													

	#Controler Value
	#Must be between -1 and 1
	#Rate Matrice Elements
	#Rate = [rx ry rt] (transpose)
	rx = x.to_f/200     										#X distance between the origin and the displacement on X Axis
	ry = y.to_f/200	  											#Y distance between the origin and the displacement on Y Axis
	origin = x.to_f == 0 && y.to_f == 0
	if (origin)													#If origin (x,y) with x = 0, y = 0
		rt = 0
	elsif (x.to_f != 0)											
		rt = -(Math.cos(Math.atan(y.to_f/x.to_f)))				
	else														#If (x,y) with x = 0
		rt = 0
	end
	#rx ry values are the values from the Javascript joystick controler
	#Example: X axis with 50% power (100px of displacement) will gave us rx = 0.5
	#Use the formula x/200  with x the number of displacement pixel. Same for y.
	#rt is the angular speed we do not want the robot to rotate in this mode so we fixe it to 0
	
	#Default Matrix
	m = Matrix[[Math.cos(180/toRad),Math.sin(180/toRad),l],[Math.cos(-60/toRad),Math.sin(-60/toRad),l],[Math.cos(60/toRad),Math.sin(60/toRad),l]]
	
	#Input Matrix
	vd = Matrix[[rx*vxmax],[ry*vymax],[rt]]

	#Voltage Const. Matrix
	ce = Matrix[[e0,0,0],[0,e1,0],[0,0,e2]]

	#PWM Output Matrix
	vwCurrent = m * vd
	pwm = vwCurrent

	#If one of the elements of Vw Matrice is above Max_Value multiply the current matrix by the Voltage Const. Matrix Ce
	isGreaterThanMaxValue = vwCurrent.element(0,0) > max_Value || vwCurrent.element(1,0) > max_Value || vwCurrent.element(2,0) > max_Value
	isLessThanMaxValue = vwCurrent.element(0,0) < -max_Value || vwCurrent.element(1,0) < -max_Value  || vwCurrent.element(2,0) < -max_Value
	if (isGreaterThanMaxValue || isLessThanMaxValue)
		vwNew = ce * (m * vd)
		pwm = vwNew
	end

	#For console verifications
	# print "Returned PWM:\n#{pwm}\n"
	# print "x = #{x} | y = #{y}\n"  
	# print "rx = #{rx} | ry = #{ry} | rt = #{rt}\n"
	return pwm
end

#init_serial
init_server