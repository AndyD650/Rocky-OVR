NUM_REGISTRATIONS = 20

path = File.expand_path(__FILE__).split("/")
path.pop
path = path.join("/")

CLOCK_IN = File.join(path, 'start-shift.rb')
CLOCK_OUT = File.join(path, 'end-shift.rb')
GROMMET_REGISTER = File.join(path, 'make-grommet-request.rb')
API_REGISTER = File.join(path, 'make-api-request.rb')

def run(cmd, args)
  `ruby #{cmd} #{args.join(" ")}`
end

session_id = "'My Session::#{Time.now.to_i}'"
partner_tracking_id = "'customid'"
partner_id = 1

base_args = [session_id, partner_tracking_id, partner_id]

run(CLOCK_IN, base_args)

error_cases = [
  [:first_name, "VR_WAPI_Invalidsignaturecontrast"], # Grommet removes and resubmites
  [:first_name, "VR_WAPI_InvalidOVRPreviousCounty"], # Gives up
  [:address, "wrong@field.com"] # Rocky errors and never submits to PA
]
error_idx = 0


NUM_REGISTRATIONS.times do |i|
  first_name = "Valid Name"
  address = "1 Main St"
  if i % 5 == 0
    if error_idx >= error_cases.length
      error_idx = 0
    end
    error_case = error_cases[error_idx]
    if error_case[0] == :first_name
      first_anme = error_case[1]
    elsif error_case[0] == :address
      address = error_case[1]
    end
    error_idx += 1
  end
  run(GROMMET_REGISTER, [base_args, first_name, address].flatten)
end

NUM_REGISTRATIONS.times do |i|
  first_name = "Test #{i}"
  run(API_REGISTER, [partner_id, first_name].flatten)
end


run(CLOCK_OUT, [base_args, 0, NUM_REGISTRATIONS].flatten)

