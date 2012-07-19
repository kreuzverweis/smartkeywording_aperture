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

script SK4AAppDelegate
	property parent : class "NSObject"
    
    property helpURL : "http://wwww.kreuzverweis.com/"
-- WHEN SWITCHING, REMEMBER TO CLEAR PREFERENCES
-- DEV	
--    property clientSecret : "7c1925be-5358-44b8-8396-e0f42d2f1c48"
--    property clientToken : "f882ee5a-956c-4254-a18f-376fcf572c2c"
-- PRODUCTION
	property clientSecret : "f21a3a2f-e970-44c1-a7a5-519cb89ad185"
    property clientToken : "41eafb6b-aaab-4abc-b714-58484489fab2"
	
	-- references to UI elements
	property mainWindow : missing value
	property searchField : missing value
	property logField : missing value
    property prefText : missing value
	
	-- Webservice connection
	property completionsWebservice : missing value
	property currentCompletions : missing value
	property currentProposals : missing value
	
	-- Aperture connection
	property ApertureInterface : missing value
	
	-- autocompletion
	property completionTimer : missing value
	property completePosting : false
	property currentSelection : missing value
	property completeTextField : missing value
	property searchFieldEditor : missing value
	
	-- proposed and existing Tags
	property tagProposalsController : missing value
	property tagsExistingController : missing value
	property pollingTimer : missing value
	property existingTagsTableView : missing value
	property proposedTagsTableView : missing value
	property oldSelectedTags : {}
    -- user defaults
    property userDefaults : missing value
	
	(*
	adding and removing tags
	*)
	
	on addTag_(sender)
	--	tell ApertureInterface to ensureApertureRunning()
		set nameString to searchField's stringValue() as string        
        tell ApertureInterface to addTag_(nameString)
		refreshAll()
	end addTag_
	
    
	on addSelectedTags_(sender)
	--	tell ApertureInterface to ensureApertureRunning()
  		set ls to tagProposalsController's numberOfRowsInTableView_(missing value)
		repeat with i from 0 to ls
			if proposedTagsTableView's isRowSelected_(i) then
				set keyword to tagProposalsController's tableView_objectValueForTableColumn_row_(missing value, 0, i)
                tell ApertureInterface to addTag_(keyword)
      		end if
		end repeat
        refreshAll()
	end addSelectedTags_
	
	on removeSelectedTags_(sender)
	--	tell ApertureInterface to ensureApertureRunning()
  		set ls to listsize() of tagsExistingController
		repeat with i from 0 to ls
			if existingTagsTableView's isRowSelected_(i) then
				set tagName to tagsExistingController's tableView_objectValueForTableColumn_row_(missing value, 0, i)
				tell ApertureInterface to removeTag_(tagName)
  			end if
		end repeat
        refreshAll()
	end removeSelectedTags_
	
	(*
	Refresh Table Views
	*)
	
	on refreshAll()
	--	tell ApertureInterface to ensureApertureRunning()
		tell ApertureInterface to set selectedTags to its getTagsForSelection
		-- we first only use data from aperture. Proposals from Webservice are handeled through a callback.
        if not 1 equals oldSelectedTags's isEqualToSet_(selectedTags) then
            set oldSelectedTags to selectedTags
            tell current application's class "NSMutableArray" to set currentProposals to its array()
            set request to completionsWebservice's ProposalRequestWithKeywords_andDelegate_(selectedTags, me)
            tell completionsWebservice to sendRequest_(request)
            refreshExistingTags()
            refreshProposedTags()
        end if
	end refreshAll
    
    on refreshExistingTags()
  		tell tagsExistingController to clear()
		tell ApertureInterface to set selectedTags to its getTagsForSelection
        tell current application's class "NSMutableArray" to set selectedTagsArray to its arrayWithArray_(selectedTags's allObjects())
        selectedTagsArray's sortUsingSelector_("localizedCaseInsensitiveCompare:")
        repeat with tag in selectedTagsArray
            repeat with i from 1 to selectedTags's countForObject_(tag)
                tell tagsExistingController to add_row(tag)
            end repeat
        end repeat    
		existingTagsTableView's reloadData()
	end refreshExistingTags
	
	on refreshProposedTags()
  		tell tagProposalsController to clear()
		tell ApertureInterface to set selectedTags to its getTagsForSelection
		-- proposals from Webservice
		if not currentSelection is {} then
			repeat with keyword in currentProposals's allObjects()
              	if 0 is equal to (selectedTags's containsObject_(keyword)) then
					tell tagProposalsController to add_row(keyword)
				end if
			end repeat
		end if
(*		-- proposals from Aperture
		tell ApertureInterface to set allTags to its getTagProposals_(selectedTags's allObjects())
		repeat with tagName in allTags's allObjects()
            if 0 equals selectedTags's containsObject_(tagName) then
                 if 0 equals tagProposalsController's contains_(tagName) then
                    tell current application's class "Synset" to set synset to its alloc()'s init()'s autorelease()
                    tell synset to set its label to tagName
                    tell tagProposalsController to prependProposal_(synset)
                 end if
            end if
        end repeat
 *)
        proposedTagsTableView's reloadData()
	end refreshProposedTags
	
	
	(* 
	Autocompletion for search Field
	*)
	
	on control_textView_completions_forPartialWordRange_indexOfSelectedItem_(theControl, textView, completions, charRange, theIndex)
	 	set partialString to searchField's stringValue() as string
		set startIndex to (|location| of charRange) + 1
		
		tell class "NSMutableArray" of current application to set results to its array()
		
        -- proposals from webservice
		repeat with keyword in currentCompletions's allObjects()
            if not results's containsObject_(keyword) > 0 then
                results's addObject_(keyword)
            end if
		end repeat
        
        -- proposals from Aperture
		tell ApertureInterface to set allTags to its getAllTags
		repeat with tagName in allTags's allObjects()
			set tagName to tagName as string
			if tagName starts with partialString then
				if not results's containsObject_(tagName) > 0 then
					results's addObject_(tagName)
				end if
			end if
		end repeat
       
        if not (results's |count|() is 0) then 
            -- if only proposal is current string, skip it.
            if (results's |count|() is 1) and (partialString equals (results's objectAtIndex_(0) as string)) then 
                return missing value
            else 
                -- add current partial string, so it does not get overwritten by autocompletion, but only of it is not first in the list
                if not (partialString equals (results's objectAtIndex_(0) as string)) then
                    if |length| of charRange > 0 then results's insertObject_atIndex_(partialString, 0)
                end if
            end if
        else
            return missing value
        end if
         
         
		return results
	end control_textView_completions_forPartialWordRange_indexOfSelectedItem_
	
	on controlTextDidChange_(nsNotificationObj)
        tell current application's class "NSArray" to set currentCompletions to its array()
        -- ask webservice for new completions, but wait half a second in case the user is still typing.
	    completionTimer's invalidate()
        set userInfo to nsNotificationObj's userInfo()
        set completeTextField to userInfo's objectForKey_("NSFieldEditor")
        set nameString to completeTextField's |string|()
        if nameString's |length|() > 3 then
            tell class "NSTimer" of current application to set completionTimer to its scheduledTimerWithTimeInterval_target_selector_userInfo_repeats_(0.3, me, "requestCompletion:", nameString, false)
        else
            trigger_completion()
        end if
	end controlTextDidChange_
	
	on requestCompletion_(timer)
        set nameString to timer's userInfo()
        set request to completionsWebservice's CompletionRequestWithPrefix_andDelegate_(nameString, me)
        tell completionsWebservice to sendRequest_(request)
    end requestCompletion_
	
	-- the UI part
	on trigger_completion()
      	--  prevent calling "complete" too often, can result in stack overflow
		if (completePosting is false) then
			set completePosting to true
			completeTextField's complete_(missing value)
			set completePosting to false
		end if
	end trigger_completion
		
 
    (*
     Webservice API Interface
     *)
    
	on raise_error(err)
        set message to "error " & err's code & ": " & err's localizedDescription 
        log message as string
        logField's setStringValue_(message)
       -- display dialog the (message as string) buttons {"OK"} default button 1 with icon stop with title "tag - error"
    end raise_error
	
	on displayOnline()
		logField's setStringValue_("Connected to keywording webservice.")
	end displayOnline
	
    on receiveCompletions_forRequest_(newCompletions, request)
        displayOnline()
        tell current application's class "NSMutableArray" to set currentCompletions to its array()
        repeat with completion in newCompletions 
            currentCompletions's addObject_(completion)
        end repeat    
        trigger_completion()
    end receiveCompletions_WithError_ 
    
    on receiveProposals_forRequest_(newProposals, request)
        displayOnline()
        tell current application's class "NSMutableArray" to set currentProposals to its array()
        repeat with proposal in newProposals 
            currentProposals's addObject_(proposal)
        end repeat    
        refreshProposedTags()
    end receiveCompletions_forRequest_ 
    
    on requestFailed_WithError_(request, err)
        raise_error(err)
    end requestFailed_WithError_ 
      
 	(*
	highlighting for tables
	*)
	
	on tableView_willDisplayCell_forTableColumn_row_(tableView, theCell, col, row)
     	set theFont to 0
		set fontsize to current application's class "NSFont"'s smallSystemFontSize()
		if tableView is equal to existingTagsTableView then
			set selectionSize to length of currentSelection
			tell tagsExistingController to set tagCardinality to its countForRow_(row) as integer
			if tagCardinality < selectionSize then
				tell current application's class "NSFont" to set theFont to systemFontOfSize_(fontsize)
			else
				tell current application's class "NSFont" to set theFont to boldSystemFontOfSize_(fontsize)
			end if
		else
			tell current application's class "NSFont" to set theFont to boldSystemFontOfSize_(fontsize)
		end if
		theCell's setFont_(theFont)
	end tableView_willDisplayCell_forTableColumn_row_
	
    (*
     custom behaviour for Search Field
     *)
    
	-- Override default field editor for search field, in order to replace not only the last word but everything on autocompletion
	on windowWillReturnFieldEditor_toObject_(sender, toObject)
		if toObject is equal to searchField then
			if searchFieldEditor is missing value then
				tell current application's class "KFSearchFieldC" to set searchFieldEditor to its alloc()'s init()
				searchFieldEditor's setFieldEditor_(true)
			end if
			return searchFieldEditor
		end if
		return missing value
	end windowWillReturnFieldEditor_toObject_

    
	(*
	Poll, as Aperture Scripting does not allow to track selection changes.	
	*)
	
	on setupPolling()
		tell class "NSTimer" of current application to set pollingTimer to its scheduledTimerWithTimeInterval_target_selector_userInfo_repeats_(0.5, me, "poll:", missing value, true)
	end setupPolling
	
	on poll_(timer)
		-- TODO: Does not handle the case that a keyword is added in Aperture.
		set oldSelection to currentSelection as list
        tell ApertureInterface to updateApertureSelection()
		tell ApertureInterface to set currentSelection to its getApertureSelection as list
		if not oldSelection is equal to currentSelection then
			refreshAll()
		end if
	end poll_
	
    
	(*
	Application event handlers
	*)
    
	on applicationShouldHandleReopen_hasVisibleWindows_(application, flag)
        performDeminiaturize_(me)
        return 0
    end
    
    on newDocument_(sender)
		mainWindow's orderFront_(me)
	end newDocument_
	
	on performClose_(sender)
		mainWindow's orderOut_(me)
		quit
		delay 10 -- so nothing else will happen asynchronously before we have quit
	end performClose_
	
	on performDeminiaturize_(sender)
		mainWindow's orderFront_(me)
	end performDeminiaturize_
	
	on awakeFromNib()
        setupWebservicePreferences()
        mainWindow's orderFront_(me)
    end awakeFromNib

    on setupWebservicePreferences()
        tell current application's class "NSMutableDictionary" to set defaults to its dictionary()
        defaults's addObject_forKey_("userId", "userId")
        userDefaults's setInitialValues_(defaults)
        
        tell completionsWebservice to setDefaultMaxResults_(20)
        tell completionsWebservice to setOAuthClientSecret_(clientSecret)
        tell completionsWebservice to setOAuthClientToken_(clientToken)
        tell completionsWebservice to setOAuthUserId_(userDefaults's values's valueForKey_("userId"))
        
        log "current user id: " & completionsWebservice's oAuthUserId
        
        if "userId" equals completionsWebservice's oAuthUserId as text then 
            tell completionsWebservice to set userId to its createUser()
            userDefaults's defaults's setObject_forKey_(userId, "userId")
            tell completionsWebservice to setOAuthUserId_(userDefaults's values's valueForKey_("userId"))
        end if
    end  setupWebservicePreferences
        
	on applicationWillFinishLaunching_(aNotification)
		tell class "NSTimer" of current application to set completionTimer to its timerWithTimeInterval_target_selector_userInfo_repeats_(0.5, me, "requestCompletion:", missing value, true)
		tell current application's class "NSMutableArray" to set currentProposals to its array()
		tell current application's class "NSMutableArray" to set currentCompletions to its array()
		tell current application's class "NSCountedSet" to set oldSelectedTags to its |set|()
        
		tell ApertureInterface to waitForAperture()

		refreshAll()
        setupPolling()
	end applicationWillFinishLaunching_
	
	on applicationShouldTerminate_(sender)
		return current application's NSTerminateNow
	end applicationShouldTerminate_
	
	
end script