require 'find'
require 'digest'

src_folder_location = "/Users/Jake/Desktop/Tech" #source
manifest_location = "/Users/Jake/.basecamp" # manifest
propresenter_location = "/Applications/ProPresenter\ 6.app" # opens if no associated files are opened

server_mount_timeout = 60 # timeout after 1min

server_attempts = 0
while (!File.directory?(src_folder_location)) # while the source folder doesnt exist (eg. server hasnt been mounted)
    puts "Waiting for source folder to be mounted..."
    server_attempts += 1
    if server_attempts >= server_mount_timeout # if we have reached our timeout
        system %{osascript -e 'tell application (path to frontmost application as text) to display dialog "Could not access JONAH. Mount the server and import new presentations manually." buttons {"OK"} with icon stop'}
        abort("Could not find source folder. Quitting...") # quit
    end
    sleep 1 # wait 1sec before trying again
end

pro6x_file_paths = []
Find.find(src_folder_location) do |path| # for each file (recursive search) in the source folder
    pro6x_file_paths << path if path =~ /.*\.pro6x$/ # if extension is pro6x (pp6 bundle), add it to the filepath array
    puts "Searching " + path
end
puts "* * * * * * *"
puts "Checking if manifest exists..."
if File.exist?(manifest_location) # if the manifest already exists
    puts "Manifest found"
else
    puts "No manifest found... creating an empty one"
    file = File.open(manifest_location,"w") # create empty manifest file (~/.basecamp)
    file.clos
end

puts "Parsing manifest..."

hashes_found = [] # an array of pro6x file hashes in manifest
line_num=0
text=File.open(manifest_location).read # read manifest file
text.gsub!(/\r\n?/, "\n") # replace newlines
text.each_line do |line| # for each line in the manifest...
  print "    Entry #{line_num += 1} --> #{line}"
  hashes_found.push(line.gsub!("\n", "")) # add the hash to our array
end

if hashes_found.empty? # no results in manifest
    puts "No manifest entries found"
end

puts "* * * * * * *"
puts "Checking bundle hashes against manifest..."

bundles_imported = 0 # total number of bundles imported

pro6x_file_paths.each do |path| # for each pro6x file in our source folder+subfolders
    print path
    bundleHash = (Digest::MD5.hexdigest File.read path) # md5 hash the file
    puts " --> " + bundleHash
    if hashes_found.include? bundleHash # if the hash is found in the manifest...
        puts path + " already opened" # dont do anything
    else
        puts "Opening bundle at #{path}" 
        system %{open "#{path}"} # open the path w/ pp6 if it wasnt in the manifest
        puts "Writing hash #{bundleHash} to manifest"
        open(manifest_location, 'a') do |f| # append the imported pro6x hash to the manifest
            f << bundleHash + "\n"
        end
        bundles_imported += 1
    end
end

if bundles_imported > 0 # if we imported 1 or more bundles
    puts "Successfully imported #{bundles_imported} bundles"
else
    puts "No bundles needed to be imported! Opening ProPresenter..."
    system %{open "#{propresenter_location}"} # open propresenter because it wasnt automatically opened from import
end
