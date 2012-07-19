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

script TableViewController
	property parent : class "NSObject"
	property contentSet : missing value
	property contentArray : missing value
	property setModified : true
    property initialized : false
	
	on addAll_(countedSet)
		set setModified to true
		repeat with anElement in countedSet's allObjects()
			repeat with i from 1 to countedSet's countForObject_(anElement)
				contentSet's addObject_(anElement)
			end repeat
            contentArray's addObject_(anElement)
		end repeat
	end addAll_
	
	on add_row(rowValue)
		set setModified to true
		contentSet's addObject_(rowValue)
        if (contentArray's containsObject_(rowValue) equals 0) then contentArray's addObject_(rowValue)
	end add_row
	
	on removeAll_(countedSet)
		set setModified to true
		repeat with anElement in countedSet's allObjects()
			repeat with i from 1 to contentSet's countForObject_(anElement)
				contentSet's removeObject_(anElement)
			end repeat
            contentArray's removeObject_(anElement)
		end repeat
	end removeAll_
	
	on remove_row(rowValue)
		set setModified to true
		repeat with i from 1 to contentSet's countForObject_(rowValue)
			contentSets's removeObject_(rowValue)
            contentArray's removeObject_(rowValue)
        end repeat
   end remove_row
	
	on clear()
		set setModified to true
		contentSet's removeAllObjects()
        contentArray's removeAllObjects()
	end clear
	
	on countForObject_(anObject)
		return contentSet's countForObject_(anObject)
	end countForObject_
	
	on countForRow_(row)
		-- regenerateArray()
		set anObject to contentArray's objectAtIndex_(row)
		return countForObject_(anObject)
	end countForRow_
	
	on listsize()
		return contentSet's |count|()
	end listsize
	
	on regenerateArray()
		if setModified then
            if contentSet's |count|() > 0 then 
                set roArray to contentSet's allObjects()
                if not roArray is missing value then
                    tell current application's class "NSMutableArray" to set contentArray to its arrayWithArray_(roArray)
             --       contentArray's sortUsingSelector_("localizedCaseInsensitiveCompare:")
                else
                    tell current application's class "NSMutableArray" to set contentArray to its array()
                end if
            else 
                tell current application's class "NSMutableArray" to set contentArray to its array()
            end if
            set setModified to false
    	end if
	end regenerateArray
	
	##################################################
	# TableView
	
	(*
       Below are three NSTableView methods of which two are mandatory.
       
       Mandatory methods: 
           These can be found in NSTableViewDataSource.
               tableView_objectValueForTableColumn_row_
               numberOfRowsInTableView_
       
       Optional method:
           This is found in NSTableViewDelegate.
               tableView_sortDescriptorsDidChange_
    *)
	
	on tableView_objectValueForTableColumn_row_(aTableView, aColumn, aRow)
		-- regenerateArray()
		set ls to listsize()
		if ls is missing value then return end
		if ls is 0 then return end
		set resultVal to contentArray's objectAtIndex_(aRow)
		if (resultVal is missing value) then return end
		return resultVal
	end tableView_objectValueForTableColumn_row_
	
	on numberOfRowsInTableView_(aTableView)
        if initialized then
           -- regenerateArray()
            return listsize()
        else
            return 0
        end if
	end numberOfRowsInTableView_
	
	on awakeFromNib()
		tell class "NSCountedSet" of current application to set contentSet to its |set|()
		tell class "NSMutableArray" of current application to set contentArray to its array()
        set initialized to true
	end awakeFromNib
	
end script

