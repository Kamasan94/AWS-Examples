require 'aws-sdk-s3'
require 'pry'
require 'securerandom'

bucket_name = EMV['BUCKET_NAME']
puts bucket_name
region = 'us-east-1'

client = Aws::S3::Client.new

resp = client.create_bucket({
    bucket: bucket_name,
    create_bucket_configuration: {
        location_contraint: region
    }
})

number_of_files = 1 + rand(6)
puts "number_of_files: #{number_of_files}"

number_of_files.times.each do |i|
    puts "iL #{i}"
    filename = "file_#{i}.txt"
    output_path = "/tmp/#{filename}"

    File.open(output_path, "w") do |f| {
        s3.put_object(bucket: 'bucket-name', key: 'object-key', body: f)
    }
end