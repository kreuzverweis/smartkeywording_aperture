(*

Copyright 2012 Kreuzverweis Solutions GmbH

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

*)

script ApertureInterface
	property parent : class "NSObject"
	
--	property ApertureInterfaceSQLite : missing value
	
	property allTagsNeedsUpdate : false
	property allTags : missing value
	property proposalTagsNeedsUpdate : false
	property proposalTags : missing value
	property existingTagsNeedsUpdate : false
	property existingTags : missing value
	
	property apertureSelection : {}
	property apertureLibrary : {}
	property sqliteConnection : missing value
	
	on awakeFromNib()
		tell current application's class "NSCountedSet" to set allTags to its |set|()
		tell current application's class "NSCountedSet" to set proposalTags to its |set|()
		tell current application's class "NSCountedSet" to set existingTags to its |set|()
	end awakeFromNib
	
	on flatten(aList)
    	if class of aList is not list then
			return {aList}
		else if length of aList is 0 then
			return aList
		else
			return flatten(first item of aList) & flatten(rest of aList)
		end if
	end flatten
	
	on listToCountedSet(theList)
		tell current application's class "NSCountedSet" to set countedSet to its |set|()
		repeat with anItem in theList
			countedSet's addObject_(anItem)
		end repeat
		return countedSet
	end listToCountedSet
    
    -- Aperture stores Unicode Charactes in decomposed form, which is not understood by our webservice (or anyone else.)
    on normalizeStringsInList(d_strings)
        set c_strings to {}
        repeat with keyword in d_strings
            tell current application's class "NSString" to set d_kw to its stringWithString_(keyword)
            set c_kw to d_kw's precomposedStringWithCanonicalMapping()
            copy c_kw to end of c_strings
        end repeat
        return c_strings
    end normalizeStringsInList
	
	on getActiveLibraryPath()
        set firstLib to do shell script "defaults read com.apple.aperture LibraryPath"
        ensureApertureRunning()
        tell application "Aperture"
			tell library 1
				set libName to name
			end tell
		end tell
        (*
         log "Searching for location of Aperture Library named: " & libName & " ..."
		set searchCommand to "mdfind '" & libName & "' | grep \\.aplibrary$"
		set libNames to do shell script searchCommand
     	set firstLib to first paragraph of libNames
         *)
		log "library path is: " & firstLib
		set apertureLibrary to libName
		return firstLib
	end getActiveLibraryPath
	
	on getTagProposals_(existingTags)
		tell current application's class "NSCountedSet" to set countedSet to its |set|()
(*	
        repeat with currentTag in existingTags
			set tags to ApertureInterfaceSQLite's getExistingTagsForTag_(currentTag)
			repeat with aTag in tags's allObjects()
				countedSet's addObject_(aTag)
			end repeat
		end repeat
 *)
		return countedSet
	end getTagProposals_
	
	on updateAllTagsAndProposalsCache()
		if allTagsNeedsUpdate then
            ensureApertureRunning()
            set allTagsNeedsUpdate to false
			set resultList to {}
            tell current application's class "NSCountedSet" to set allTags to its |set|()
			tell application "Aperture"
				tell every image version
					tell every keyword
                        -- Aperture uses unusual ecoding for unicode chars
                 		set c_kw to name
                        allTags's addObject_(c_kw as text)
                        -- copy c_kw to end of resultList
					end tell
				end tell
			end tell
			-- set allTags to listToCountedSet(normalizeStringsInList(flatten(resultList)))
		end if
	end updateAllTagsAndProposalsCache
	
	on getAllTags()
		updateAllTagsAndProposalsCache()
		return allTags 
	end getAllTags
	
	on getTagsForSelection()
		if existingTagsNeedsUpdate then
            ensureApertureRunning()
            set aList to {}
			tell application "Aperture"
				set imageSel to (get selection)
                repeat with i from 1 to count of imageSel
					tell item i of imageSel
						tell every keyword
                            set c_kw to name -- as text
                           copy c_kw to end of aList
						end tell
					end tell
				end repeat
			end tell
            set existingTags to listToCountedSet(normalizeStringsInList(flatten(aList)))
	        set existingTagsNeedsUpdate to false
		end if
		return existingTags
	end getTagsForSelection
	
    (*
	on getFileNamesForSelection()
		set aList to {}
		tell application "Aperture"
			set imageSel to (get selection)
			repeat with i from 1 to count of imageSel
				tell item i of imageSel
					tell other tag "MasterLocation"
						copy value to end of aList
					end tell
				end tell
			end repeat
		end tell
		tell current application to set resultArray to its class "NSMutableArray"'s array()
		repeat with fileName in aList
			log fileName
			resultArray's addObject_(fileName as string)
		end repeat
		return resultArray
	end getFileNamesForSelection
     *)
	
	on addTag_(tagName)
		ensureApertureRunning()
        set tag to tagName as string
		tell application "Aperture"
			set imageSel to (get selection)
			repeat with i from 1 to count of imageSel
				tell item i of imageSel
					make new keyword with properties {name:tag, parents:{"Kreuzverweis"}}
				end tell
			end repeat
		end tell
		allNeedUpdate()
	end addTag_
	
	on removeTag_(tagName)
		ensureApertureRunning()
        set tag to tagName as string
		tell application "Aperture"
			set imageSel to (get selection)
			repeat with i from 1 to count of imageSel
                try -- ignore if image does not have this tag
					tell item i of imageSel to delete keyword tag
				end try
			end repeat
		end tell
		allNeedUpdate()
	end removeTag_
    
    on updateApertureSelection()
        ensureApertureRunning()
        tell application "Aperture" to set sel to its selection
        if not (sel is equal to apertureSelection) then
            set apertureSelection to sel
            tell application "Aperture" to set libName to name of library 1
            if not (apertureLibrary is equal to libName) then
                set apertureLibrary to libName
--                ApertureInterfaceSQLite's initDbConnectionWithLibraryPath_(getActiveLibraryPath())
            end if
            allNeedUpdate()
        end if
    end onUpdateApertureSelection
	
	on getApertureSelection()
        return apertureSelection as list
	end getApertureSelection
	
	on canAccessApertureSelection()
  		if not application "Aperture" is running then return false
		-- The following looks a bit complicated, but the try block and the 
		-- check outside the try block are necessary to capture the event
		-- of the free Aperture version restarting and showing the splash
		-- screen. In this case, Aperture is running, but the scripting
		-- bridge is not yet initialized. 
		set canAccessSelection to false
		tell application "Aperture"
			try
				set imageSel to selection
				if not imageSel is missing value then set canAccessSelection to true
			end try
		end tell
		return canAccessSelection
	end canAccessApertureSelection
	
	on allNeedUpdate()
		set allTagsNeedsUpdate to true
		set proposalTagsNeedsUpdate to true
		set existingTagsNeedsUpdate to true
	end allNeedUpdate
	
	on ensureApertureRunning()
		if not application "Aperture" is running then
			waitForAperture()
		else
			if not canAccessApertureSelection() then waitForAperture()
		end if
	end ensureApertureRunning
	
	on waitForAperture()
   	if not application "Aperture" is running then
			set question to "Smart Keywording needs Aperture to work properly. What do you want to do?"
			display dialog the (question) buttons {"Quit", "Launch Aperture"} default button 1 with icon note
			if not (button returned of result = "Launch Aperture") then
				quit
				delay 10 -- put the event loop asleep, so nothing else can happen before we terminate
			end if
		end if
		tell application "Aperture" to run
		repeat until application "Aperture" is running
			display dialog "Waiting for Aperture..." buttons {"Abort & Quit"} giving up after 1
			if button returned of result = "Abort & Quit" then
				quit
				delay 10 -- put the event loop asleep, so nothing else can happen before we terminate
			end if
		end repeat
		repeat until canAccessApertureSelection()
			display dialog "Waiting for Aperture..." buttons {"Abort & Quit"} giving up after 1
			if button returned of result = "Abort & Quit" then
				quit
				delay 10 -- put the event loop asleep, so nothing else can happen before we terminate
			end if
		end repeat
--		ApertureInterfaceSQLite's initDbConnectionWithLibraryPath_(getActiveLibraryPath())
	end waitForAperture
	
end script
