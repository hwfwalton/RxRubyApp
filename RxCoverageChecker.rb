require 'tk'
require 'sqlite3'

class MyBox   
    def initialize(titleText, promptText, windowWidth, maxLength)
        @searchText = TkVariable.new
        @resultsText = TkVariable.new
        @allResults

        # Create the root window
        root = TkRoot.new do
            title titleText
            minsize(windowWidth,maxLength)
            maxsize(windowWidth,maxLength)
        end

        # ======================================================================
        # Frames

        # Create the frame to house the prompt and text box
        promptFrame = TkFrame.new(root) do
            padx 15
            pady 5
            pack('side'=>'top', 'fill'=>'x')
        end

        # Used to create a dividing line between the prompt and results
        dividerFrame = TkFrame.new(root) do
            background "gray"
            pack('padx'=>15, 'pady'=>5, 'side'=>'top', 'fill'=>'x')
        end

        # Creat the frame to populate with the results
        resultsFrame = TkFrame.new(root) do
            pack('padx'=>15, 'pady'=>5, 'side'=>'top', 'fill'=>'both', 'expand' => 1)
        end 

        # ======================================================================
        # promptFrame Contents

        # Define the font used by both the prompt and text field
        promptFont = TkFont.new('family'=>'Helvetica', 'size'=>14)

        # Create the prompt to the user to promptFrame
        promptLabel = TkLabel.new(promptFrame) do
            wraplength windowWidth-30 
            text promptText
            font promptFont
            anchor 'w'
            justify 'left'
            pack('fill'=>'x', 'side'=>'top')
        end

        # Create the text field the user enters into
        searchBox = TkEntry.new(promptFrame,
            :font => promptFont,
            :width => 19,
            :validate => 'key',
            :validatecommand => proc{searchEvent} )
            .pack('pady'=>5, 'side'=>'left') 

        # Link the text in the searchbox to the searchText variable for access
        searchBox.textvariable = @searchText

        # Creates button to update search results
        searchButton = TkButton.new(promptFrame,
            :text => "Update Results",
            :font => promptFont,
            :command=> proc{searchEvent}).pack('padx'=>10, 'side'=>'left')


        # ======================================================================
        # resultsFrame contents

        resultsFont = TkFont.new('family'=>'Helvetica', 'size'=>12)

        # Creat the label to populate with results
        resultsLabel = TkLabel.new(resultsFrame) do
            wraplength(windowWidth - 30)
            font resultsFont
            anchor 'w'
            justify 'left'
            pack('side'=>'top', 'fill'=>'both')
        end
        resultsLabel.textvariable = @resultsText

        # Creates button to move through search results
        @searchButton = TkButton.new(resultsFrame,
            :text => "More Results",
            :font => resultsFont,
            :command=> proc{setResultsText(1)}).pack('padx'=>15, 'side'=>'bottom', 'fill'=>'x')
        @searchButton.state = 'disabled'

        # Divider between the search results and the button
        buttonDividerFrame = TkFrame.new(resultsFrame) do
            background "gray"
            pack('pady'=>5, 'side'=>'bottom', 'fill'=>'x')
        end

        Tk.mainloop
    end

    # =========================================================================
    # =========================================================================
    # UTILITY FUNCTIONS

    # Called upon change to the search box or the user clicking the button
    # Searches the db for drugs matching the user's input and returns which
    # carriers cover them
    def searchEvent
        input = @searchText.value

        begin
            output = ""
            db = SQLite3::Database.open "drugs.db"

            # Fuzzy matches the user input against the db entries
            matches = db.execute "SELECT Name,EqClass FROM Drugs WHERE Name LIKE '#{input}%';"
            output = "No Results" if matches.empty?

            # For each match found in the db, looks up which Carriers cover it
            matches.each do |match|
                output += "#{match[0].upcase}"

                if not match[1].nil?
                    equivalents = db.execute "SELECT Name FROM Drugs WHERE EqClass = #{match[1]}"
                    output += "("
                    equivalents.each do |eqDrug|
                        output += eqDrug[0]+", " if not eqDrug[0].include? match[0]
                    end
                    output.chop!.chop!
                    output.chop! if output[-1] == "("
                    output += ")" if output[-1] != "("
                end
                output += ":\n"

                coverage = db.execute "SELECT Carriers.Name, CoverageTier
                            FROM Carriers, Drugs, Covers
                            WHERE Carriers.Id = Covers.CarrierId
                            AND Drugs.Id = Covers.DrugId
                            AND Drugs.Name = '#{match[0]}';"

                coverage.each do |carrier|
                    output += "#{carrier[0]} (tier #{carrier[1]})\n"
                end
                output += "_________________________________________\n\n"
            end unless matches.empty?

        rescue SQLite3::Exception => e
            puts "Exception occured"
            puts e
        ensure
            db.close if db
            @allResults = output
            setResultsText(0)
        end unless input.empty?


        return true
    end 

    # 0 = set to start, 1 = next page
    def setResultsText(action)
        lineBreaks = (0 ... @allResults.length).find_all {|i| @allResults[i,1]=="\n"}

        if action == 0
            if lineBreaks.length < 30 
                displayText = @allResults
                @searchButton.state = 'disabled'
            else 
                displayText = @allResults[0..lineBreaks[32]]
                @searchButton.state = 'normal'
                @resultsPage = 1
            end
        else
            if (@resultsPage+1)*32 < lineBreaks.length
                startBreak = lineBreaks[@resultsPage*32]+1
                endBreak = lineBreaks[(@resultsPage+1)*32]
                displayText = @allResults[startBreak..endBreak]
                @resultsPage += 1
            else
                displayText = @allResults[lineBreaks[@resultsPage*32]+1..-1]
                @searchButton.state = 'disabled'
            end
        end

        @resultsText.value = displayText
    end
end


# =========================================================================


newTitle = "Rx Coverage Checker"
promptText = "Please type your prescription below to check its coverage availability"
width = 400
maxLength = 800
box1=MyBox.new(newTitle, promptText, width, maxLength)
