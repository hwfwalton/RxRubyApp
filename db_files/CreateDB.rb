require 'sqlite3'
require 'pdf-reader'

def addEntries(carrier, filename)
    begin
        fo = File.open(filename, "r")
        db = SQLite3::Database.open "drugs.db"
        db.execute "INSERT INTO Carriers(Name) VALUES('#{carrier}');"

        fo.each_line do |line|
            # Split the line and pull out the drug's name and its coverage tier
            drug_name, coverage_tier = line.downcase.split('|')

            # If the entries are empty, skip to the next
            next if drug_name.empty? or coverage_tier.nil?


            # Remove any leading or trailing whitespace
            drug_name.strip! unless drug_name.strip.nil?

            # We are protected from repeat values by the tables' constraints so
            # we don't need to check for existence
            db.execute "INSERT INTO Drugs(Name) VALUES ('#{drug_name}');"
            db.execute "INSERT INTO Covers(CarrierId, DrugId, CoverageTier)
                            SELECT Carriers.Id, Drugs.Id, #{coverage_tier} 
                            FROM Drugs, Carriers 
                            WHERE Drugs.Name = '#{drug_name}' AND Carriers.Name = '#{carrier}';"

            #puts drug_name+" added to #{carrier}"

        end
    rescue SQLite3::Exception => e
        puts "Exception occured"
        puts e
    ensure
        db.close if db
        fo.close if fo
    end
end

carriers = ["Anthem", "BlueShield", "Cigna", "Medicare"]

carriers.each do |carrier|
    addEntries(carrier, carrier+".txt")
    puts carrier+" entries added"
end

