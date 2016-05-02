import processing.serial.*;
import cc.arduino.*;

Arduino arduino;
String port = "/dev/cu.usbmodem1421"; // change to the serial port that corresponds with Arduino
String wordKey = "a2a73e7b926c924fad7001ca3111acd55af2ffabf50eb4ae5"; // Wordnik API Key
String soundKey = "66ac9aab04d71b8579ffe44158577ff0b1df0ae9"; // Freesound API Key #1
String backupsoundKey = "56d89b6e69bfbe486edba70ceaf7b6a10bab26a2"; // Freesound API Key #2
String wordnikUrl;
String freesoundUrl;
String soundUrl;
String word;

void setup() { 
    arduino = new Arduino(this, port, 57600);

    // Set the Arduino digital pins as inputs and outputs
    arduino.pinMode(4, Arduino.INPUT);
}

void draw() {
/*
    // For testing without arduino input or output  
    if (mousePressed == true) {
        getSounds();
    }
*/  
    // If button is pressed, get sounds
    if (arduino.digitalRead(4) == Arduino.HIGH){
        getSounds();
    }
}

//to be replaced by "if button pressed,"
void getSounds(){
    
    PrintWriter output; // creates a text file to store the urls
    int second = second();
    int minute = minute();
    int hour = hour();
    int day = day();
    int month = month();
    output = createWriter("freesoundLinks" + "_" + month + "_" + day + "_" + hour + "_" + minute + "_" + second +".txt"); 
  
    // get 10 random words
    wordnikUrl = "http://api.wordnik.com/v4/words.xml/randomWords?hasDictionaryDef=";
    wordnikUrl += "false"; // change to true if you want to only search words that have a dictionary definition
    wordnikUrl += "&includePartOfSpeech=noun&minCorpusCount=0&maxCorpusCount=-1&minDictionaryCount=1&maxDictionaryCount=-1&minLength=5&maxLength=-1&limit=10&api_key=";
    wordnikUrl += wordKey;
    XML xml = loadXML(wordnikUrl);
    XML [] words = xml.getChildren("wordObject");
    for (int i = 0; i < words.length; i ++){
        word = words[i].getChild("word").getContent();
        println(word);
        // if word is two words, separate and put %20 in between
        String [] match = match(word, "\\s");
        if (match != null) {
            String [] twowords = split(word, ' ');
            word = twowords[0] + "%20" + twowords[1];
        }
        // search freesound for tags including the word
        freesoundUrl = "http://www.freesound.org/apiv2/search/text/?query=";
        freesoundUrl += word;
        freesoundUrl += "&format=xml&token=";
        freesoundUrl += soundKey;
        XML xmlsound = loadXML(freesoundUrl);
        int count = int(xmlsound.getChild("count").getContent());
        println(count);
        // if there are results, get the ids for the sound files. this page has all of the links.
        if ( count > 0){
            // store the tag
            output.println(word);
            XML [] soundids = xmlsound.getChildren("results");
            for (int j = 0;;){
                XML [] listitem = soundids[j].getChildren("list-item");
                // make two arrays of 10 strings that the next loop will fill with urls
                String [] urls = new String [listitem.length];
                String [] publicUrl = new String [listitem.length];
                // iterate through each id, get the url for the soundfiles
                for (int h = 0; h < listitem.length; h ++){
                    int ids = int(listitem[h].getChild("id").getContent());
                    // go to the more detailed xml page for each id. this pulls up a new page at each iteration.
                    soundUrl = "http://www.freesound.org/apiv2/sounds/";
                    soundUrl += ids;
                    soundUrl += "/?format=xml&token=";
                    soundUrl += soundKey;
                    XML xmlsoundid = loadXML(soundUrl);
                    // store public url for soundfile
                    publicUrl[h] = xmlsoundid.getChild("url").getContent();
                    // get the link to high quality mp3 file of the id, store all links in an array
                    XML finallinks = xmlsoundid.getChild("previews");
                    urls[h] = finallinks.getChild("preview-hq-mp3").getContent();
                }
                launch(urls[0]);
                println(urls[0]);
                output.println(publicUrl[0]);
                output.close();
                return;
            }
        }
    }
}