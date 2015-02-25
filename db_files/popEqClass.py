import base64
import hmac
import hashlib
import sys
import requests
import sqlite3
drug_name = ""

def make_api_call(drug_name):
    secret_key = "TpQoBd34fo6Iu2OCyiYgPA=="
    api_key = "2a6c42b0aa"
    api_url = "https://api.goodrx.com/fair-price"
    
    query_string = "name="+drug_name+"&api_key="+api_key

    signature = hmac.new(secret_key, msg=query_string.encode("utf8"), digestmod=hashlib.sha256).digest()
    b64_sig = base64.b64encode(signature, "__")

    complete_url = api_url+"?"+query_string+"&sig="+b64_sig
    return complete_url


def update_eq_class(name, class_id):
    c.execute("UPDATE Drugs SET EqClass = "+str(class_id)+" WHERE Name = \'"+name+"\';")    

if __name__ == "__main__":

    # fp = open('log.txt', 'w')
    conn = sqlite3.connect(sys.argv[1])
    c = conn.cursor()
    c.execute("SELECT Name FROM Drugs;")
    drugs_list = [n[0] for n in c.fetchall()]

    # Value to to start at if a new equivalence class is created. pulls the largest EqClass id
    c.execute("SELECT MAX(EqClass) FROM Drugs WHERE EqClass IS NOT NULL")
    maxVal = c.fetchone()[0]
    new_eq_class_id = (maxVal+1 if maxVal else 1)
    print "new_eq_class_id: "+str(new_eq_class_id)


    for drug_name in drugs_list:
        url = make_api_call(drug_name)  
        r = requests.get(url)

        # Continue to next iteration if the request failed. Means the drug wasn't in the GoodRx db
        if not r.json()['success']: continue

        equivalence_list = r.json()['data']['generic'] + r.json()['data']['brand']

        # First collect the list of all the drugs in our db matching the returned eq_drugs
        # eq_drug_matches = [eq_match for eq_match in c.execute() for eq_drug in equivalence_list]
        eq_drug_matches = []
        for eq_drug in equivalence_list:
            c.execute("SELECT Name FROM Drugs WHERE Name LIKE \'"+eq_drug+"%\' AND NAME != \'"+drug_name+"\';")
            eq_drug_matches += [n[0] for n in c.fetchall()]

        # Now, among the matches we found, we're checking if any of them already have an eq class
        eq_class_finds = []
        for eq_drug in eq_drug_matches:
            c.execute("SELECT Name FROM Drugs WHERE Name = \'"+eq_drug+"\' AND EqClass IS NOT NULL;")
            eq_class_finds += [n[0] for n in c.fetchall()]

        existing_eq_class_found = False
        class_id = 0


        #If there is an entry in that list, then we have an eq class. pull its id
        if eq_class_finds:
            existing_eq_class_found = True
            c.execute("SELECT EqClass FROM Drugs WHERE Name = \'"+eq_class_finds[0]+"\';")
            class_id = c.fetchone()[0]

            

        #if existing_eq_class_found:
        if existing_eq_class_found and (len(eq_drug_matches) > len(eq_class_finds)):
            eq_drug_matches.append(drug_name)
            [update_eq_class(eq_drug, class_id) for eq_drug in eq_drug_matches]
            # msg = "Extending EqClass "+str(class_id)+": "+', '.join(["{0}".format(n) for n in eq_drug_matches])
            # fp.write(msg.encode("utf8"))
        # The len() check unsures we don't recreate an existing CqClass
        elif eq_drug_matches and (len(eq_class_finds) == 0):
            eq_drug_matches.append(drug_name)
            class_id = new_eq_class_id;
            new_eq_class_id += 1
            [update_eq_class(eq_drug, class_id) for eq_drug in eq_drug_matches]
            # msg = "Creating EqClass "+str(class_id)+": "+', '.join(["{0}".format(n) for n in eq_drug_matches])
            # fp.write(msg.encode("utf8"))

    #fp.close()
    conn.commit()
    conn.close()
