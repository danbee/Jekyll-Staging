#!/usr/bin/ruby


# Staging/unstaging script for Jekyll blog posts.
# 
# by Matt Gemmell
# 
# Web: http://mattgemmell.com
# Twitter: http://twitter.com/mattgemmell


# This script moves a specified draft post into Jekyll's folder structure,
# and temporarily stashes all other posts so the site will build quickly.
# 
# This is for people who keep their drafts outside of Jekyll's folder structure.
# 
# It can also reverse the process when you're done, of course.
# 
# This is useful when you're working on a post using Jekyll's server.


# Requirements: just Ruby itself.


# Usage: Run the script with no arguments to see usage instructions.


# License: CC Attribution-ShareAlike
# http://creativecommons.org/licenses/by-sa/4.0/


# ========================================
# Configuration
# ========================================


# Your Jekyll site's local root directory (it has the "_config.yml" file in it).
$jekyll_root = "~/Dropbox/blog/mattgemmell.com" # full path ("~" is OK too)

# Wherever you keep your local in-progress drafts, outside of your Jekyll site.
$drafts_dir = "~/Dropbox/writing/blog" # full path ("~" is OK too)

# File-extension for your drafts and post files.
$file_extension = "markdown" # without period (use "*" for all)

# Note: It's assumed that your drafts' filenames DON'T have date-prefixes.


# ========================================
# You probably DON'T need to touch anything below here!
# ========================================


# Other directories within Jekyll's root. The defaults should be fine.
$posts_dir_name = "_posts" # Should already be in the root directory.
$stash_dir_name = "_stash" # Will be created if necessary.

# Filename details for posts. The defaults should be fine.
$file_date_prefix_format = "%Y\-%m\-%d\-" # for Ruby's DateTime strftime
$file_date_prefix_regexp = /\d+-\d+-\d+-/ # regexp to match date format above


# ===  Start of functions  ===


def first_matching_file_in_dir(the_filename_glob, the_dir_path)
	Dir.chdir(the_dir_path)
	matches = Dir.glob(the_filename_glob)
	if matches.count == 0
		puts "No matches found in #{the_dir_path}."
		return false
	elsif matches.count > 1
		puts "Found #{matches.count} matching files (#{matches.join(", ")})"
	end
	
	filename = matches[0]
	puts "Using file \"#{filename}\"."
	return filename
end


def directory_exists(the_dir_path)
	# Check for a directory at path.
	
	if File.exist?(the_dir_path)
		# Something's there. Check if it's a directory.
		#puts "Found something at given path."
		if File.directory?(the_dir_path)
			# It exists, and it's a directory. We're done.
			#puts "It's a directory."
			return true
		else
			# Abort
			#puts "It's not a directory"
		end
	end
	
	return false
end


def create_dir_if_necessary(the_dir_path)
	# Check for a directory at path, creating it if necessary.
	
	# Check to see if an item exists at that path.
	if directory_exists(the_dir_path)
		return true
	else
		# It doesn't exist. Create it.
		#puts "Nothing found at given path."
		begin
			Dir.mkdir(the_dir_path, 0755)
			#puts "Created the directory: #{the_dir_path}"
			return true
		rescue SystemCallError
			# If we failed to create the directory, abort.
			#puts "Failed to create the directory."
			return false
		end
	end
	
	return false
end


def isolate(the_filename_glob)
	# Moves all files from posts to stash, except those matching the glob.
	
	# Move all files from posts into stash.
	cmd = "mv #{$posts_dir}/*.#{$file_extension} #{$stash_dir}/"
	result = `#{cmd}`
	
	# Move the matching files back into posts.
	cmd = "mv #{$stash_dir}/*#{the_filename_glob}* #{$posts_dir}/"
	result = `#{cmd}`
end


def integrate()
	# Moves all files from stash back into posts.
	
	# Move all files from stash into posts.
	cmd = "mv #{$stash_dir}/*.#{$file_extension} #{$posts_dir}/"
	result = `#{cmd}`
end


def stage_file(the_filename_glob)
	# Stages the given file.
	
	puts "Staging \"#{the_filename_glob}\"…"
	
	# Grab specified file (glob) from drafts folder.
	full_glob = "*#{the_filename_glob}*.#{$file_extension}"
	filename = first_matching_file_in_dir(full_glob, $drafts_dir)
	if filename == false
		puts "Couldn't find a file to stage. Aborting."
		exit
	end
	
	# Move file to posts directory, prefixing its filename with today's date.
	require "Date"
	today = DateTime.now()
	prefix = today.strftime($file_date_prefix_format)
	new_filename = "#{prefix}#{filename}"
	
	cmd = "mv #{$drafts_dir}/#{filename} #{$posts_dir}/#{new_filename}"
	result = `#{cmd}`
	
	# Isolate the staged file in posts, moving all other posts to stash.
	isolate(new_filename)
	
	puts "File staged as \"#{new_filename}\"."
end


def unstage_file(the_filename_glob)
	# Unstages the given file, or the first staged file if none is specified.
	
	if (the_filename_glob)
		puts "Unstaging \"#{the_filename_glob}\"…"
	else
		puts "Unstaging first staged file…"
	end
	
	# Grab specified file (glob) from posts folder.
	if (the_filename_glob)
		full_glob = "*#{the_filename_glob}*.#{$file_extension}"
	else
		full_glob = "*.#{$file_extension}"
	end
	filename = first_matching_file_in_dir(full_glob, $posts_dir)
	if filename == false
		puts "Couldn't find a file to unstage. Aborting."
		exit
	end
	
	# Move file to drafts directory, removing date from its filename.
	new_filename = filename.sub($file_date_prefix_regexp, "")
	
	cmd = "mv #{$posts_dir}/#{filename} #{$drafts_dir}/#{new_filename}"
	result = `#{cmd}`
	
	# Move all stashed files back into posts.
	integrate()
	
	puts "Unstaging complete."
end


def show_help()
	puts "`#{$0} FILENAME_GLOB` stages the first matching draft."
	puts "`#{$0} #{$unstage_flag}` unstages the first staged post."
	puts "`#{$0} #{$unstage_flag} FILENAME_GLOB` unstages the first matching staged post."
end


# ===  End of functions  ===


# Handle input
$unstage_flag = "-u" # flag passed to the script to request unstaging
filename_glob = nil
unstage = false

if ARGV.count == 0
	puts "No filename or arguments specified."
	show_help()
	exit
elsif ARGV.count == 1
	if ARGV[0] == $unstage_flag
		# This is the "unstage" flag without a filename.
		unstage = true
	else
		# This is the "stage" command with a filename.
		filename_glob = ARGV[0]
	end
elsif ARGV.count == 2
	# If there are two arguments, the second one is the filename.
	filename_glob = ARGV[1]
	if ARGV[0] == $unstage_flag
		unstage = true
	else
		puts "Input not recognised."
		show_help()
		exit
	end
end

# All paths MUST be expanded before we begin.
$drafts_dir = File.expand_path($drafts_dir)
$jekyll_root = File.expand_path($jekyll_root)
$stash_dir = "#{$jekyll_root}/#{$stash_dir_name}"
$posts_dir = "#{$jekyll_root}/#{$posts_dir_name}"

# Check that drafts, root, and posts directories exist.
if directory_exists($drafts_dir) == false
	puts "Drafts directory doesn't exist: #{$drafts_dir}"
	exit
end
if directory_exists($jekyll_root) == false
	puts "Jekyll root directory doesn't exist: #{$jekyll_root}"
	exit
end
if directory_exists($posts_dir) == false
	puts "Jekyll posts directory doesn't exist: #{$posts_dir}"
	exit
end

# Ensure stash_dir exists, creating it if necessary.
if directory_exists($stash_dir) == false
	if create_dir_if_necessary($stash_dir) == false
		# Something went wrong. Abort.
		puts "Couldn't create stash directory: #{$stash_dir}"
		puts "Aborting."
		exit
	else
		puts "Created stash directory: #{$stash_dir}"
	end
end

# Get the job done. It's a bit anticlimactic, really.
if unstage
	unstage_file(filename_glob)
else
	stage_file(filename_glob)
end
