#!/usr/bin/praat
#praat script

# I used this special version of MaSCoT to extract the text from all text grids transcribed so far.
# This only involved changing directories and a tier and regex.

# NOTICE: This file uses UTF-8! Do NOT save it as anything else, or things will break!

debug = 0
debugEUT = 0
debugRestAndExcl = 0

if debug or debugEUT
	clearinfo
endif

script_name$ = "MaSCoT-RecursiveSubdirectories"
version$ = "3.1"
author$ = "Scott Sadowsky"

#####################################################################################################
# MaSCoT-RecursiveSubdirectories.praat
#####################################################################################################
# SCRIPT:		MAssive Speech COrpora Tool (MaSCoT) - Recursive Subdirectories
# AUTHOR:		Scott Sadowsky - http://sadowsky.cl - ssadowsky REMOVETHISBIT gmail com
# DATE:		3 July 2016
# VERSION:	3.1
# DESCRIPTION:	Opens all LongSound + TextGrid pairs in the subdirectories of a given directory
#			and, using a complex set of regexes and other user specifications, allows the
#			following to be done to matching intervals:
#			  * Extract sound to WAV files
#			  * Extract labels to TextGrid files (with option to keep only certain tiers)
#			  * Extract text from the 'utter' and 'utter-phnm' tiers and save it in plain text files.
# USAGE NOTES:	- The source sound must be a LongSound object.
#		    	- Both the TextGrid and the LongSound must have identical names
#			  and must be selected before running the script.
# THANKS:		GetTierName procedure adapted from a script by Mietta Lennes.
#			Some other parts of this script are also based on a script by
#			Mietta Lennes.
# NOTE:		Based on MaSCoT v2.5
#
#####################################################################################################
# TO DO / KNOWN BUGS
#####################################################################################################
# *	At least when extracting TG interval labels to .txt files, once the script hits a file that
#	has certain problem conditions, it fails to process the labels in all subsequent files (it does
#	write the headers, though). These problem conditions include having no hits at all to extract
#	(i.e. an untranscribed section) and not having a final silence after the section being extracted
#	from.
#
# * When using extraction option 2 (at least), most tier labels aren't read!
#
#####################################################################################################
# MaSCoT Changelog
#####################################################################################################
#
# 3,0 Fixed the problem where text grid processing is mysteriously aborted in the middle of the file.
#
# 2,9
# - Added improvements made to MaSCoT-RecursiveSubdirectories-SoM.praat to this version of the script:
#   Properly process regexes in exclusion tier. Before, the regex string was incorrectly processed
#   as a string match.
# - Added additional strings to log file output, to make this useful for phoneme/allophone extraction.
# - Changed log file header output, so that all the variables in the form are recorded.
# - Disabled the subroutine that counts the total number of items to be extracted, since it's pretty
#   close to useless.
# -
#
# 2,8
# Didn't document these changes.
#
# 2,7
# Added ability to extract text grid intervals to a text file, with time stamp.
#
# 2,6
# This version is for working with recursive subdirectories.
#
# 2,4
# Added option to exclude intervals on a user-selected tier that contain text that matches any regular expression.
# Added option to put sequential interval number before interval labels in some situations.
#
# 2,2
# Moved to two-digit versioning system.
# Added ability to normalize extracted audio. Normalization is done to the peak value.
#
# 2,1,9
# Added ability to apply fade-in and fade-out to extracted audio.
# Made adding a left and right margin to the extracted audio optional.
#
# 2,1,6
# Added more info to the log file that MaSCoT produces.
#
# 2,1,3
# Changed default field contents for Regex, since the bracketed expression [áéíóú] works irregularly (!!!).
#
# 2,1,0
# Added ability to save TextGrids along with sound files.
#####################################################################################################

#####################################################################################################
# Define certain variables.
#####################################################################################################
useRestrict = 0
useSoundExtractionTier = 0
#number_of_characters_in_filename_prefix = 15
date$ = date$()
first_number = 1

#####################################################################################################
# Form
#####################################################################################################
form MAssive Speech COrpus Tool (MaSCoT) ver. 3.0 (Recursive Subdirectory Version)
	#sentence Base_directory E:/AV_Corpus/!!_Recordings/Coscach/Gen_2--3o_Medio_y_Uni/
	sentence Base_directory E:/Corpora/COSCACH/Recordings/__MISC-LOCALITIES__/

	optionmenu Actions_to_perform: 4
		option Extract WAV & TG files
		option Extract WAV & TG files (leave only speaker utter)
		option Extract TG labels to text file (timestamps)
		option Extract TG labels to text file (no_timestamps)

	#sentence Useful_symbols i̯ u̯ d̪ ʤ d͡ʒ ʝ ɲ ɾ ʃ t̪ t͡ɾ ʧ t͡ʃ ʂ ˈ | ‖
	#comment REGEX EXAMPLES: ^line$  <word> · [a-z]  [ieaou]  [^0-9]  (a|b|c)  \d  \D  \l  \L ·  ?  .  .*  .+  {2,5}

	# These are the default options as of 2,9. They're designed for extracting analyses of allophones of specific phonemes.
	sentence Search_tier utter
	sentence Regular_expression_to_use .+
	sentence Restrict_search_to_this_tier_(optional) instruments
	sentence And_to_this_section_of_the_tier_(optional) interview

	# # These options are for actions 1 and 2 above (extract WAVs & TGs). These were the defaults until 2.8.
	# sentence Search_tier instruments
	# sentence Regular_expression_to_use interview
	# sentence Restrict_search_to_this_tier_(optional)
	# sentence And_to_this_section_of_the_tier_(optional)

	# # These options are good, functional defaults for actions 3 and 4 above (extract TG labels to text file)
	# sentence Search_tier utter
	# sentence Regular_expression_to_use .+
	# sentence Restrict_search_to_this_tier_(optional) instruments
	# sentence And_to_this_section_of_the_tier_(optional) interview

	sentence Extract_sound_from_this_tier_(optional)
	sentence Use_labels_from_this_tier_(optional) phones1
	sentence Additional_labels_from_this_tier_(optional) words

	# THESE ARE THE RESTRICTIVE SETTINGS. Might cause problems with extraction of interview section.
	sentence Exclude_intervals_from_this_tier_(optional) misc
	sentence If_above_intervals_match_following_regex_(optional) XXX|Xxx|xxx|ZZZ|Zzz|zzz|REVIEW|Review|review|WRONG|Wrong|wrong|REPEAT|Repeat|repeat|UNKNOWN|Unknown|unknown|SPANISH|Spanish|spanish|.*\?.*|mxff.+

	boolean Write_headers_or_logfiles no
	boolean Add_margin_to_extracted_interval no
	comment Time margin to add to beginning and end of each extracted interval:
	positive Margin_(seconds) 0.005

	boolean Normalize_intensity yes
	boolean Apply_fade_in_and_fade_out_to_extracted_audio yes
	positive Fade_length_(seconds) 0.025

	comment What folder do you want to save the WAV files in? (Use the full path, ending with "/")
	text Output_folder E:/Corpora/_PROCESSING_/praat-output/MaSCoT-Recursive/
	positive Number_of_characters_in_filename_prefix 15
	positive Maximum_length_of_each_field_in_WAV_filenames 15
	boolean Put_sequential_number_before_interval_labels_(optional) no

	#comment What are the first and last intervals you want to extract?
	integer First_interval 1
	integer Last_interval_(0=to_end) 0
endform

#####################################################################################################
# Give form variables shorter, English names.
#####################################################################################################
restrictionTierName$ = restrict_search_to_this_tier$
restrictionText$ = and_to_this_section_of_the_tier$
searchTierName$ = search_tier$
extractionTierName$ = extract_sound_from_this_tier$
labelTierName$ = use_labels_from_this_tier$
addLabelTierName$ = additional_labels_from_this_tier$
maxLength = maximum_length_of_each_field_in_WAV_filenames
exclusionTier$ = exclude_intervals_from_this_tier$
exclusionRegex$ = if_above_intervals_match_following_regex$

#####################################################################################################
# Perform necessary processing of certain form fields.
#####################################################################################################

	# Initializa some variables
	extract_WAV_files = 0
	also_extract_TextGrids = 0
	leave_only_speaker_utterances = 0
	extract_tier_labels_to_txt = 0
	add_timestamp_to_extracted_text = 0

	# Set variables for actions to perform
	if actions_to_perform == 1
		extract_WAV_files = 1
		also_extract_TextGrids = 1
	elsif actions_to_perform == 2
		extract_WAV_files = 1
		also_extract_TextGrids = 1
		leave_only_speaker_utterances = 1
	elsif actions_to_perform == 3
		extract_tier_labels_to_txt = 1
		add_timestamp_to_extracted_text = 1
	else
		extract_tier_labels_to_txt = 1
	endif

	# If no search tier is provided, die, EXCEPT if the extract_tier_labels_to_txt option is chosen
	if extract_tier_labels_to_txt == 0
		if searchTierName$ == ""
			exit ERROR!'newline$''newline$'You must input the name of the tier you want to search in. 'newline$''newline$'Close this window by clicking on <OK>, close the script window with <CANCEL>, and try again... 'newline$''newline$'
		endif
	endif

	# Add slash to end of base directory name if none present
	if not right$(base_directory$) == "/" or right$(base_directory$) == "\"
			base_directory$ = base_directory$ + "/"
	endif

	# Set variable for use in WAV filename
	extractionTierLabel$ = extractionTierName$

	# If no extraction tier is provided, use the search tier for this.
	if extractionTierName$ == ""
		extractionTierName$ = searchTierName$
	endif

	# If no tier is provided for the source of labels, use the sound tier for them.
	if labelTierName$ == ""
		labelTierName$ = searchTierName$
	endif

	# If there is text in both the restriction tier name and the restriction text fields, set the restriction flag
	if ( restrictionTierName$ <> "" ) and ( restrictionText$ <> "" )
		useRestrict = 1
	else
		useRestrict = 0
	endif

	# # DEBUG
	# appendInfoLine: "restrictionTierName$ = ``", restrictionTierName$, "´´"
	# appendInfoLine: "restrictionText$ = ``", restrictionText$, "´´"
	# appendInfoLine: "useRestrict = ", useRestrict

	# If there is text in both the exclusion tier name field and the exclusion regex field, set the exclusion flag
	if ( exclusionTier$ <> "" ) and ( exclusionRegex$ <> "" )
		useExclusion = 1
	else
		useExclusion = 0
	endif

	if addLabelTierName$ <> ""
		useAddLabel = 1
	else
		useAddLabel = 0
	endif

	if ( extractionTierName$ <> "" ) and ( extractionTierName$ <> searchTierName$ )
		useSoundExtractionTier = 1
	else
		useSoundExtractionTier = 0
	endif


#####################################################################################################
# Main script body STARTS
#####################################################################################################

# Create a list of subdirectory names under the base directory
Create Strings as directory list... directoryList 'base_directory$'*
numOfSubdirectories = Get number of strings

# Loop through subdirectories and call the various procedures that make up the script
if numOfSubdirectories != 0
	for d to numOfSubdirectories

		# Get string list of directory names
		select Strings directoryList
		subdirName$ = Get string... d

		# Add trailing slash
		currFullPath$ = base_directory$ + subdirName$ + "/"

		# Jump to procedure that processes each recording
		call processEachRecording

	endfor
else
	exit ERROR!'newline$''newline$'There aren´t any subdirectories to process in the base directory!
endif

# Clean up object list
selectObject: "Strings directoryList"
Remove

#####################################################################################################
# Main script body ENDS
#####################################################################################################



#####################################################################################################
# PROCEDURE:	processEachRecording
# DESCRIPTION:	Finds the number of a tier that has a given label.
#####################################################################################################
procedure processEachRecording

##########################################################################
# Get list of TextGrid files in the current subdirectory and put in string list
###########################################################################
Create Strings as file list... list 'currFullPath$'*.TextGrid
numberOfFiles = Get number of strings

for currFile to numberOfFiles

	# NEW IN 3,0: Reset variables
	# The recursive processing doesn't work right when processing more than one file.
	# Processing stops before it should, and the script moves on to the next file.
	# This new section attempts to fix that.
	#
	# AND IT LOOKS LIKE IT DOES!!!!!
	numberOfIntervals = 0
	first_interval = 1
	last_interval = 0

	select Strings list

	# Get current filename
	currFilename$ = Get string... currFile

	# Set base file name
	baseName$ = currFilename$ - ".TextGrid"

	# Set WAV file name and load this file
	wavName$ = baseName$ + ".wav"
	Open long sound file... 'currFullPath$''wavName$'

	# Load TextGrid
	Read from file... 'currFullPath$''currFilename$'

	# Load the current TextGrid.
	soundName$ = selected$ ("TextGrid", 1)
	select TextGrid 'soundName$'

	# Get the numbers of the tiers whose names were given.
	call GetTierNum 'searchTierName$' searchTierNum
	call GetTierNum 'labelTierName$' labelTierNum

	# Get tier numbers of certain tiers if chosen options make them relevant
	if useAddLabel == 1
		call GetTierNum 'addLabelTierName$' addLabelTierNum
	endif

	call GetTierNum 'extractionTierName$' extractionTierNum

	if ( useRestrict == 1 )
		call GetTierNum 'restrictionTierName$' restrictionTierNum
	endif

	if ( useExclusion == 1 )
		call GetTierNum 'exclusionTier$' exclusionTierNum
	endif

	# Check the interval values and correct them if necessary.
	numberOfIntervals = Get number of intervals... searchTierNum

	if first_interval > numberOfIntervals
		exit ERROR!'newline$''newline$'There aren´t 'first_interval' intervals in the tier labeled ``'searchTierName$'´´.'newline$''newline$'
	endif

	if last_interval > numberOfIntervals
		last_interval = numberOfIntervals
	endif

	if last_interval == 0
		last_interval = numberOfIntervals
	endif

	# Set default values for certain variables.
	hits = 0
	intervalstart = 0
	intervalend = 0
	searchInterval = 1
	intnumber = first_number - 1
	soundIntervalName$ = ""
	labelIntervalName$ = ""
	addLabelIntervalName$ = ""
	intervalfile$ = ""
	endoffile = Get finishing time
	prefix$ = left$ ("'soundName$'", number_of_characters_in_filename_prefix)



	# # +++++ NEW IN 2,9.
	# # TESTING: DISABLE THIS ENTIRE SUBROUTINE!

	# Count number of hits (i.e. matching intervals) BEFORE doing the extraction run.

	# # NOTE: This is used for nothing more than providing the hit count in WAV and TG file names.
	# for searchInterval from first_interval to last_interval

		# # Get label of current interval in the search tier
		# searchIntervalLabel$ = Get label of interval... searchTierNum searchInterval

		# # Set default value: Interval NOT valid.
		# this_interval_is_valid = 0

		# # Get the position of current search interval in the search tier, to find
		# # corresponding intervals on the other tiers
		# searchSelectionStart = Get start point... searchTierNum searchInterval
		# searchSelectionEnd = Get end point...  searchTierNum searchInterval

		# # RESTRICT SEARCH TO A CERTAIN SECTION OF A CERTAIN TIER, IF DESIRED

		# # Get the number of the interval on the restriction tier that corresponds to the
		# # current search interval, if the user wants to restrict the search to a given tier.
		# if ( useRestrict == 1 )

			# restrictionInterval = Get interval at time... restrictionTierNum searchSelectionStart
			# restrictionIntervalLabel$ = Get label of interval... restrictionTierNum restrictionInterval

			# # If the search expression matches current interval AND the restriction expression also matches
			# # then proecss it (set this_interval_is_valid = 1)
			# if index_regex ( searchIntervalLabel$, regular_expression_to_use$ )
				# ... and ( restrictionIntervalLabel$ == restrictionText$ )
				# this_interval_is_valid = 1
			# endif

		# # If no restriction tier is selected, then just check to see if the search expression
		# # matches the current interval
		# elsif ( useRestrict == 0 )
			# if index_regex (searchIntervalLabel$, regular_expression_to_use$)
				# this_interval_is_valid = 1
			# endif

		# # If a weird value comes up, quit script
		# else
			# exit INVALID useRestrict value ('useRestrict')!

		# endif

		# # EXCLUDE INTERVALS THAT CONTAIN CERTAIN TEXT

		# # NEW IN 2,4: Check exclusion tier for regex to be excluded (if desired)
		# if ( useExclusion == 1 )

			# # Get the number of the interval on the exclusion tier that corresponds
			# # to the current search interval
			# exclusionInterval = Get interval at time... exclusionTierNum searchSelectionStart
			# exclusionIntervalLabel$ = Get label of interval... exclusionTierNum exclusionInterval

			# # Compare the current label on the exclusion tier with the exclusion regex.
			# # If there´s a match --meaning a non-zero return value-- don´t process this interval.
			# exclusionTest = index_regex (exclusionIntervalLabel$, exclusionRegex$)
			# if ( exclusionTest <> 0 )
				# this_interval_is_valid = 0
			# else
				# this_interval_is_valid = 1
			# endif

			# # # DEBUG
			# # appendInfoLine: newline$, "exclusionInterval = ", exclusionInterval
			# # appendInfoLine: "exclusionIntervalLabel$ = ``", exclusionIntervalLabel$, "´´"
			# # appendInfoLine: "exclusionTest = ", exclusionTest
			# # appendInfoLine: "this_interval_is_valid = ", this_interval_is_valid

		# endif

		# # If current segment meets all conditions for being counted, increase file count
		# if this_interval_is_valid == 1
		   # hits = hits + 1
		# endif

	# endfor	#	End of "Count number of hits (matching intervals)" FOR loop.

	searchInterval = 1

	###########################################################################
	# Write log file for WAV and TextGrid stuff
	###########################################################################
	if ((extract_WAV_files == 1) or (also_extract_TextGrids == 1)) and (write_headers_or_logfiles == 1)

		# Define path and name of log file and debug file.
		textfilename$ = "'output_folder$'" + "'soundName$'" + "_" + "'first_number'" + "-to-" + "'hits'" + ".txt"
		debugFilename$ = textfilename$ + ".log"

		# NEW IN 216: Print metadata to log file
		dog$ =	"======================================================================'newline$'
				...'script_name$' ver. 'version$' by 'author$''newline$''newline$'
				...Search date:'tab$''date$'.'newline$'
				...Directory:'tab$''output_folder$''newline$''newline$'
				...Search expression:'tab$''tab$''tab$''regular_expression_to_use$''newline$'
				...Tier searched:'tab$''tab$''tab$''tab$''search_tier$''newline$'
				...Sound extraction tier:'tab$''tab$''extractionTierName$''newline$'
				...Restriction tier:'tab$''tab$''tab$''restrict_search_to_this_tier$''newline$'
				...Restriction tier section:'tab$''and_to_this_section_of_the_tier$''newline$'
				...Tier used for labels:'tab$''tab$''use_labels_from_this_tier$''newline$'
				...Additional label tier:'tab$''tab$''addLabelTierName$''newline$'
				...======================================================================'newline$''newline$'"
		fileappend "'textfilename$'" 'dog$'

		# NEW IN 216: Print header row to log file
		# For reasons I can't figure out, the normal (and possibly more efficient) way of doing
		# this (if X then dog$=Y else dog$=Z) doesn't work. I have to do dog$=Y, if X then dog$=Z.
		dog$ = "INTERVAL_NUM'tab$'FILE_PREFIX'tab$'SEARCH_INT_LABEL'tab$'LABEL_INT_NAME'tab$'RESTRICTION_TXT'tab$'EXTRACTION_TIER_LABEL'newline$'"

		if ( useAddLabel == 1 )
			dog$ = "INTERVAL_NUM'tab$'FILE_PREFIX'tab$'SEARCH_INT_LABEL'tab$'ADD_INT_LABEL'tab$'LABEL_INT_NAME'tab$'RESTRICTION_TXT'tab$'EXTRACTION_TIER_LABEL'newline$'"
		endif

		fileappend "'textfilename$'" 'dog$'
	endif

	###########################################################################
	# If text grid interval text is being extracted to text files, create the text
	# file and optinally write a header to it
	###########################################################################
	if extract_tier_labels_to_txt

		# Create strings for output filename suffixes. Change certain names for CIAE project.
		if searchTierName$ == "utter"
			textExtractionFileSuffix$ = ".ortografica.txt"
		elsif searchTierName$ == "utter-phnm"
			textExtractionFileSuffix$ = ".fonemica.txt"
		else
			textExtractionFileSuffix$ = ".txt"
		endif

		# Concatenate variable values to make file name for extracted text file
		extractedTextFileName$ = output_folder$ + prefix$ + textExtractionFileSuffix$
		debugFilename$ = extractedTextFileName$ + ".log"

		# Create output file for text extraction and write first line.
		writeFileLine: extractedTextFileName$

		# If desired, write a header with useful info to the extracted txt file.
		if write_headers_or_logfiles
			#Write header to extracted text file
			appendFileLine: extractedTextFileName$, "======================================================================"
			appendFileLine: extractedTextFileName$, script_name$, " ver. ", version$, " by ", author$
			appendFileLine: extractedTextFileName$, "Search date:", tab$, tab$, tab$, tab$, date$
			appendFileLine: extractedTextFileName$, "Extraction option: ", tab$, tab$, tab$, actions_to_perform$
			appendFileLine: extractedTextFileName$, "File name:", tab$, tab$, tab$, tab$, prefix$, textExtractionFileSuffix$
			appendFileLine: extractedTextFileName$, "Directory:", tab$, tab$, tab$, tab$, output_folder$
			appendFileLine: extractedTextFileName$, "Full path:", tab$, tab$, tab$, tab$, extractedTextFileName$
			appendFileLine: extractedTextFileName$, "Speaker:", tab$, tab$, tab$, tab$, tab$, prefix$
			appendFileLine: extractedTextFileName$, ""
			appendFileLine: extractedTextFileName$, "Tier extracted:", tab$, tab$, tab$, search_tier$
			appendFileLine: extractedTextFileName$, "Section extracted:", tab$, tab$, tab$, "`", and_to_this_section_of_the_tier$, "´ in the `", restrict_search_to_this_tier$, "´ tier"
			appendFileLine: extractedTextFileName$, "Search tier:", tab$, tab$, tab$, tab$, search_tier$
			appendFileLine: extractedTextFileName$, "Search expression:", tab$, tab$, tab$, regular_expression_to_use$
			appendFileLine: extractedTextFileName$, "Restrict to sections of tier:", tab$, restrict_search_to_this_tier$
			appendFileLine: extractedTextFileName$, "...containing the expression:", tab$, and_to_this_section_of_the_tier$
			appendFileLine: extractedTextFileName$, "Sound extraction tier:", tab$, tab$, extract_sound_from_this_tier$
			appendFileLine: extractedTextFileName$, "Label tier:", tab$, tab$, tab$, tab$, use_labels_from_this_tier$
			appendFileLine: extractedTextFileName$, "Additional label tier:", tab$, tab$, additional_labels_from_this_tier$
			appendFileLine: extractedTextFileName$, "Exclude intervals from tier:", tab$, exclude_intervals_from_this_tier$
			appendFileLine: extractedTextFileName$, "...containing the regex:", tab$, tab$, if_above_intervals_match_following_regex$
			appendFileLine: extractedTextFileName$, ""
			appendFileLine: extractedTextFileName$, "Write headers or logfiles?:", tab$, tab$, write_headers_or_logfiles
			appendFileLine: extractedTextFileName$, "Add margin to extracted interval?:", tab$, add_margin_to_extracted_interval
			appendFileLine: extractedTextFileName$, "Duration of margin to add (ms):", tab$, margin
			appendFileLine: extractedTextFileName$, "Normalize intensity?:", tab$, tab$, tab$, normalize_intensity
			appendFileLine: extractedTextFileName$, "Apply fade in and fade out:", tab$, tab$, apply_fade_in_and_fade_out_to_extracted_audio
			appendFileLine: extractedTextFileName$, "Fade length (ms):", tab$, tab$, tab$, tab$, fade_length
			appendFileLine: extractedTextFileName$, "Output folder:", tab$, tab$, tab$, tab$, tab$, output_folder$
			appendFileLine: extractedTextFileName$, "Characters in filename prefix:", tab$, number_of_characters_in_filename_prefix
			appendFileLine: extractedTextFileName$, "Max filename field length:", tab$, tab$, maximum_length_of_each_field_in_WAV_filenames
			appendFileLine: extractedTextFileName$, "Add seq num before int labels?:", tab$, put_sequential_number_before_interval_labels
			appendFileLine: extractedTextFileName$, "======================================================================"
			appendFileLine: extractedTextFileName$, ""
		endif
	endif


	###########################################################################
	# Loop through all intervals in the selected tier of the TextGrid
	###########################################################################
	for searchInterval from first_interval to last_interval

		# Reset variables
		this_interval_is_valid = 0
		searchIntervalLabel$ = ""

		# Select text grid and get interval label
		select TextGrid 'soundName$'
		searchIntervalLabel$ = Get label of interval... searchTierNum searchInterval

		# Get the position of current search interval in the search tier, to find
		# corresponding intervals on the other tiers
		searchSelectionStart = Get start point... searchTierNum searchInterval
		searchSelectionEnd = Get end point...  searchTierNum searchInterval

		# DEBUG
		if debugRestAndExcl
			appendFileLine: debugFilename$, "================================================"
			appendFileLine:	debugFilename$, "searchIntervalLabel$ = ", tab$, "``", searchIntervalLabel$, "´´"
			appendFileLine: debugFilename$, ""
			appendFileLine: debugFilename$, "useRestrict =", tab$, useRestrict
			appendFileLine: debugFilename$, "INITIAL this_interval_is_valid =", tab$, this_interval_is_valid
		endif

		# IF A RESTRICTION TIER IS SPECIFIED...
		# Get the number of the interval on the restriction tier that corresponds to the
		# current search interval, if the user wants to restrict search to a certain tier section.

		if ( useRestrict == 1 )
			restrictionInterval = Get interval at time... restrictionTierNum searchSelectionStart
			restrictionIntervalLabel$ = Get label of interval... restrictionTierNum restrictionInterval

			# If current search interval label matches the regex AND the restriction interval label matches
			# the current restriction text, then set this_interval_is_valid = 1 to signal that this
			# interval is to be extracted.
			#
			# New in 2,9
			# Changed the second line below from "... and ( restrictionIntervalLabel$ == restrictionText$ )" to what it is now,
			# fixing a long-standing bug. Now the restriction label can actually process regexes properly.
			if index_regex (searchIntervalLabel$, regular_expression_to_use$)
				... and index_regex (restrictionIntervalLabel$, restrictionText$)
				this_interval_is_valid = 1
			endif

			# Debug
			if debugRestAndExcl
				appendFileLine: debugFilename$, "restrictionTierNum =", tab$, restrictionTierNum
				appendFileLine: debugFilename$, "restrictionInterval = ", tab$, restrictionInterval
				appendFileLine: debugFilename$, "restrictionIntervalLabel$ =", tab$, ">", restrictionIntervalLabel$, "<"
				appendFileLine: debugFilename$, "restrictionText$ = ", tab$, tab$, ">", restrictionText$, "<"
				appendFileLine: debugFilename$, "ENDING this_interval_is_valid = ", tab$, this_interval_is_valid
				appendFileLine: debugFilename$, ""
			endif

			# If no restriction tier or text are set, only check to see if the search expression matches
			# current search interval label in order to set this_interval_is_valid=0, thereby signalling
			# that this interval is to be extracted.
			elsif ( useRestrict == 0 )
				if index_regex (searchIntervalLabel$, regular_expression_to_use$)
					this_interval_is_valid = 1
				endif
			else
				exit useRestrict was neiter 1 nor 0, but 'useRestrict'! That means something is borked!
		endif

		# IF AN EXCLUSION TIER IS SPECIFIED...
		# NEW IN 2,4: Check exclusion tier for regex to be excluded (if desired)
		# NOTE: this_interval_is_valid=0 seems to mean "continue and process stuff".

		# NEW IN 2,9
		# Move the IF clause further below so that the content of the
		# exclusion is read no matter what.
		#if ( useExclusion == 1 )

			# DEBUG
			if debugRestAndExcl
				appendFileLine: debugFilename$, "useExclusion =", tab$, useExclusion
				appendFileLine: debugFilename$, "initial this_interval_is_valid =", tab$, this_interval_is_valid
			endif

			# Get the number of the interval on the exclusion tier that corresponds
			# to the current search interval
			exclusionInterval = Get interval at time... exclusionTierNum searchSelectionStart
			exclusionIntervalLabel$ = Get label of interval... exclusionTierNum exclusionInterval

		if ( useExclusion == 1 )

			# Check to see if the exclusion interval label matches the exclusion regex. If so,
			# the variable exclusionTest will equal something non-zero.
			exclusionTest = index_regex (exclusionIntervalLabel$, exclusionRegex$)

			if ( exclusionTest <> 0 )
				# CHANGED IN 2,7  -- DANGEROUS, EXPERIMENTAL!
				this_interval_is_valid = 0
			endif

			# DEBUG
			if debugRestAndExcl
				appendFileLine: debugFilename$, "exclusionInterval = ", tab$, exclusionInterval
				appendFileLine: debugFilename$, "exclusionIntervalLabel$ =", tab$, tab$, ">", exclusionIntervalLabel$, "<"

				appendFileLine: debugFilename$, "exclusionTest =", tab$, tab$, exclusionTest
				appendFileLine: debugFilename$, "ending this_interval_is_valid = ", tab$, this_interval_is_valid
				appendFileLine: debugFilename$, ""
			endif

		endif

		# Get the number of the interval on the extraction tier that corresponds to the current
		# search interval.				 extractionTierName$ extractionTierNum
		extractionInterval = Get interval at time... extractionTierNum searchSelectionStart
		extractionIntervalLabel$ = ""
		extractionIntervalLabel$ = Get label of interval... extractionTierNum extractionInterval

		# Extract the text from the label interval on the label tier

		# Get the number of the interval on the label tier that corresponds to the current search interval
		labelInterval = Get interval at time... labelTierNum searchSelectionStart

		# On the label tier, get the interval label that corresponds to the current search interval.
		labelIntervalName$ = ""
		labelIntervalName$ = Get label of interval... labelTierNum labelInterval

		# Get the number of the interval on the ADDITIONAL label tier that corresponds to the current search interval
		if ( useAddLabel == 1 )
			addLabelInterval = Get interval at time... addLabelTierNum searchSelectionStart

			# On the ADDITIONAL label tier, get the interval label that corresponds to the current search interval.
			addLabelIntervalName$ = ""
			addLabelIntervalName$ = Get label of interval... addLabelTierNum addLabelInterval
		endif


		###########################################################################
		# Perform the sound extraction to WAV files, if desired
		###########################################################################
		if extract_WAV_files == 1

			if this_interval_is_valid == 1
			  intnumber = intnumber + 1

				# Extract interval PLUS MARGIN
				if add_margin_to_extracted_interval == 1

					# Add margins to start and end times for extraction.
					intervalstart = Get starting point... extractionTierNum extractionInterval

					if intervalstart > margin
						intervalstart = intervalstart - margin
					else
							 intervalstart = 0
					endif

					intervalend = Get end point... extractionTierNum extractionInterval

					if intervalend < endoffile - margin
						intervalend = intervalend + margin
					else
						intervalend = endoffile
					endif

				endif

				# Extract interval WITHOUT MARGIN
				if add_margin_to_extracted_interval == 0
					# Add margins to start and end times for extraction.
					intervalstart = Get starting point... extractionTierNum extractionInterval
					intervalend = Get end point... extractionTierNum extractionInterval
				endif

				# Extract the sound from the interval. THE KEY VALUES ARE intervalstart AND intervalend *****************
				select LongSound 'soundName$'
				Extract part... intervalstart intervalend no

				# Perform fade-in and fade-out, if desired
				if apply_fade_in_and_fade_out_to_extracted_audio

					Fade in... All 0 fade_length n

					clipEndTime = Get end time
					neg_fade_length = fade_length * -1
					Fade out... All clipEndTime neg_fade_length n

			   endif

				# Normalize intensity to peak, if desired.
				if normalize_intensity
					Scale peak... 0.99
				endif

				stringLength = length (prefix$)
				if stringLength > maxLength
					prefix$ = left$ (prefix$, maxLength)
				endif

				stringLength = length (restrictionText$)
				if stringLength > maxLength
					restrictionText$ = left$ (restrictionText$, maxLength)
				endif

				stringLength = length (extractionTierName$)
				if stringLength > maxLength
					extractionTierName$ = left$ (extractionTierName$, maxLength)
				endif

				stringLength = length (labelIntervalName$)
				if stringLength > maxLength
					labelIntervalName$ = left$ (labelIntervalName$, maxLength)
				endif


				# Append ADDITIONAL label to search interval label, if user specifies an additional label.
				combinedIntervalLabel$ = searchIntervalLabel$
				if (useAddLabel == 1)
					# combinedIntervalLabel$ = searchIntervalLabel$ + "__" + addLabelIntervalName$
					combinedIntervalLabel$ = addLabelIntervalName$ + "}_{" + searchIntervalLabel$
				endif

				# The name of the sound file then consists of these elements:
				if ( useRestrict == 1 && useSoundExtractionTier == 1)
					intervalfile$ = "'output_folder$'" +
					... "'prefix$'-" +
					... "['intnumber']__" +
					... "{'combinedIntervalLabel$'}__" +
					... "utterance='labelIntervalName$'__" +
					... "restriction='restrictionText$'__" +
					... "extracted-from='extractionTierLabel$'"

				elsif ( useRestrict == 1 && useSoundExtractionTier == 0)
					intervalfile$ = "'output_folder$'" +
					... "'prefix$'-" +
					... "['intnumber']__" +
					... "{'combinedIntervalLabel$'}__" +
					... "utterance='labelIntervalName$'__" +
					... "restriction='restrictionText$'"

				elsif ( useRestrict == 0 && useSoundExtractionTier == 1)
					intervalfile$ = "'output_folder$'" +
					... "'prefix$'-" +
					... "['intnumber']__" +
					... "{'combinedIntervalLabel$'}__" +
					... "utterance='labelIntervalName$'__" +
					... "extracted-from='extractionTierLabel$'"

				else
					# Place interval number first if user selected this option: put_sequential_number_before_interval_labels
					if put_sequential_number_before_interval_labels
						intervalfile$ = "'output_folder$'" +
						... "'prefix$'-" +
						... "['intnumber']--" +
						... "{'combinedIntervalLabel$'}"
					else
						intervalfile$ = "'output_folder$'" +
						... "'prefix$'-" +
						... "{'combinedIntervalLabel$'}__" +
						... "_['intnumber']"
					endif

				endif

				intervalfileWithExt$ = intervalfile$ + ".wav"

				Write to WAV file... 'intervalfileWithExt$'
				Remove

			endif

		endif

		#####################################################################################################
		# EXTRACT TEXT GRIDS TO .TXT FILES, IF DESIRED
		#####################################################################################################
		if also_extract_TextGrids
			select TextGrid 'soundName$'
			Extract part... intervalstart intervalend no
			intervalfileWithExt$ = intervalfile$ + ".TextGrid"

			# NEW IN 26: Strip all tiers except 3 and 4 (utter & utter-phnm). For U Chile / CIAE
			if leave_only_speaker_utterances
				call stripAllTiersButUtters
			endif

			Write to text file... 'intervalfileWithExt$'
			Remove

			# Write information about the extracted sound to log file
			if write_headers_or_logfiles
				dog$ = "'intnumber''tab$''prefix$''tab$''searchIntervalLabel$''tab$''labelIntervalName$''tab$''restrictionText$''tab$''extractionTierLabel$''newline$'"
				if (useAddLabel == 1)
					dog$ = "'intnumber''tab$''prefix$''tab$''searchIntervalLabel$''tab$''addLabelIntervalName$''tab$''labelIntervalName$''tab$''restrictionText$''tab$''extractionTierLabel$''newline$'"
				endif
				fileappend "'textfilename$'" 'dog$'
			endif

		endif

		#####################################################################################################
		# NEW IN 2,7
		# Extract tier labels to .txt file
		# MODIFIED IN 3.1 FOR PHON PHONEMIC DICTIONARY WORDLIST
		#   The current version is adding filename prefixes and interval numbers no matter what. We're going
		#   to brute-force that into submission.
		#####################################################################################################
		if extract_tier_labels_to_txt

			# This is a new variable. It's what will be written to the output file.
			outputText$ = ""

			# NEW IN 2,7. Experimental! Dangerous! +++++
			if this_interval_is_valid == 1

				# Don't write anything if the interval is empty
				if searchIntervalLabel$ <> ""

					# Add timestamp to extracted text if so desired.
					if add_timestamp_to_extracted_text

						# Cut off interval start and end times at 2 decimal places
						roundedSearchSelectionStart$ = fixed$ ('searchSelectionStart', 2)
						roundedSearchSelectionEnd$ = fixed$ ('searchSelectionEnd', 2)

						# Prepend interval timestamps and text to file
						#appendFileLine: extractedTextFileName$, "[", roundedSearchSelectionStart$, " - ", roundedSearchSelectionEnd$, "]", tab$, searchIntervalLabel$

						#NEW IN 2,9
						outputText$ = "[" + roundedSearchSelectionStart$ + " - " + roundedSearchSelectionEnd$ + "]" + tab$
					endif

					#NEW IN 2,9
					# Build string of interval labels, depending on what's been extracted

					# Convert the numeric searchInterval variable into a string
					searchInterval$ = string$ (searchInterval)

					# Put together the invariable part of the output string
					outputText$ = outputText$ + prefix$ + tab$ + searchInterval$

					# Check to see if various strings exist, and if they do, add them to the output text

					if ( searchIntervalLabel$ <> "" )
						outputText$ = outputText$ + tab$ + searchIntervalLabel$
					endif

					if ( labelIntervalName$ <> "" )
						outputText$ = outputText$ + tab$ + labelIntervalName$
					endif

					if ( exclusionIntervalLabel$ <> "" )
						outputText$ = outputText$ + tab$ + exclusionIntervalLabel$
					endif

					if ( addLabelIntervalName$ <> "" )
						outputText$ = outputText$ + tab$ + addLabelIntervalName$
					endif

					# Append interval timestamps and text to file
					if ( put_sequential_number_before_interval_labels == 0 )
						appendFileLine: extractedTextFileName$, searchIntervalLabel$
					endif

					if ( put_sequential_number_before_interval_labels == 1 )
						appendFileLine: extractedTextFileName$, outputText$
					endif

				endif

			endif
		endif
	endfor	# End of searchInterval FOR loop



	#####################################################################################################
	########DEBUG
	#####################################################################################################
	if debug == 1
		printline ========== NEW DEBUG ==========
		printline useRestrict = 'useRestrict'
		printline useSoundExtractionTier = 'useSoundExtractionTier'
		printline
		printline regex = 'regular_expression_to_use$'
		printline restrictionTierName$ = 'restrictionTierName$'
		printline restrictionText$ = 'restrictionText$'
		printline extractionTierName$ = 'extractionTierName$'
		printline labelTierName$ = 'labelTierName$'
		printline labelIntervalName$ = 'labelIntervalName$'
		printline intnumber = 'intnumber'
		printline searchIntervalLabel$ = 'searchIntervalLabel$'
		printline -------------------------------
		printline
		printline
	endif

	#####################################################################################################
	# Clean up
	#####################################################################################################
	select TextGrid 'soundName$'
	plus LongSound 'soundName$'
	Remove

endfor	#	End of "currFile to numberOfFiles" FOR loop. This loops through each INTERVAL!

# -------------------------------------------------------------------------------- #
# All actions to be performed must be done BEFORE THIS POINT !!!!!!!!!!!!!!!!!!
# -------------------------------------------------------------------------------- #

	#####################################################################################################
	# Clean up strings list
	#####################################################################################################
	selectObject: "Strings list"
	Remove

endproc
#####################################################################################################
# END PROCEDURE Process each recording
#####################################################################################################



#####################################################################################################
# PROCEDURE:	stripAllTiersButUtters
# DESCRIPTION:	Eliminates all tiers but "utter" and "utter-phnm" from Coscach text grids.
#				For sharing recordings with CIAE / UChile
#####################################################################################################
procedure stripAllTiersButUtters

	# Remove all tiers except "utter" and "utter-phnm"
	Remove tier: 13
	Remove tier: 12
	Remove tier: 11
	Remove tier: 10
	Remove tier: 9
	Remove tier: 8
	Remove tier: 7
	Remove tier: 6
	Remove tier: 5
	Remove tier: 2
	Remove tier: 1

	# Rename these two tiers
	Set tier name: 1, "ortográfica"
	Set tier name: 2, "fonemica"

endproc

#####################################################################################################
# PROCEDURE:	GetTierNum .name$ .variable$
# DESCRIPTION:	Finds the number of a tier that has a given label.
# GLOBAL VARIABLES NEEDED:
#	<soundName$> is the name of the sound and TextGrid file being used.
# THANKS: Adapted from a script by Mietta Lennes.
#####################################################################################################
procedure GetTierNum .name$ .variable$

	select TextGrid 'soundName$'
	.numberOfTiers = Get number of tiers

	# Cycle through the tiers in the TextGrid and check tier names until the
	# desired one is found or all tiers have been tried unsuccessfully.
	.itier = 1
	repeat
		.currentTier$ = Get tier name... .itier
		.itier = .itier + 1
	until .currentTier$ = .name$ or .itier > .numberOfTiers

	# If no tier has the name being searched for, set the variable passed back
	# to the main part of the script (whose name is contained in .variable$) to 0.
	if .currentTier$ <> .name$
		'.variable$' = 0

	# If the tier being searched for WAS found, set the variable passed as the
	# procedure's second parameter (held in .variable$) to the tier number.
	else
		'.variable$' = .itier - 1
	endif

	# If the tier being searched for was not found, die and throw an error message.
	if '.variable$' == 0
		exit There is no tier called '.name$' in the file 'soundName$'!
	endif

endproc


