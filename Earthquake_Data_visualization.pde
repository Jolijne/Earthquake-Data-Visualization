/**
 * Program author: Jolijne, Ritsumeikan University 3rd Year
 * The SVG map is by originally from RedGolpe and modified by Prof. Cooper from Ritsumeikan University
 
 * Data obtained from the NCEI/WDS Global Significant Earthquake Database and available on Kaggle:
   https://www.kaggle.com/mohitkr05/global-significant-earthquake-database-from-2150bc
   (The data has been re-editted by Jolijne with only the data between 2000 to 2020 visible 
    and simplified from 47 columns to 17 columns. 
    Furthermore, the iso-alpha country code is added to the data in the earthquake.csv file)

 * This proram requires a particular SVG worldmap from Wikimedia Commons and licensed as Creative Commons Attribution
   (BlankMap-World-Sovereign_Nations.svg)
   The SVG world map used in the program can be found in the link:
   https://commons.wikimedia.org/wiki/File:BlankMap-World-Sovereign_Nations.svg
 * Share Alike 4.0 International license.
 * https://creativecommons.org/licenses/by-sa/4.0/deed.en
 
 * For the program to work, this program also requires a file that shows the iso-apha 2 country codes, country names, and latitudes
 
 * This visualization program loads the SVG world map and draws the earthquake data onto the map
 * The data is plotted using circles with different colors and sizes, indicating the magnitude of the earthquake
 
 * When running the program, the current earthquake data will be shown using the indicator 
 * The reason is that the attempt usage of mouseClicked() does not work well when I was trying to implement it
 * The program includes the drawings of the tectonic plates 
 * One of the main goals for this visualization is to allow users to understand that majority of the earthquakes happen due to the movement of tectonic plates
 * One part of the tectonic plate borders is highlighted in red, which indicate the "ring of fire", which is the area where large earthquakes happen frequently
 */


// Implement the map interface by using a hash table
import java.util.HashMap;

// Necessary files to run the program
String svgmapfile = "BlankMap-World-Sovereign_Nations.svg";
String earthquakedatafile = "earthquake.csv";
String countrydatafile = "countries-various.csv";

// The world map class 
class WorldMap {
  PShape map;
  String worldmapfilename = svgmapfile;
}
WorldMap worldmap = new WorldMap();

final float MAP_UNIT = 1650f;  // position of the map in the window
final float ten_east_x = MAP_UNIT-8f; // the line unit and the position of the plotted data
final float eq_to_pole_dist = MAP_UNIT; // height of the vertical lines drawn on the map 
final float x_offset = -50f; 
final float y_offset = 85f; 
final float equator_y = MAP_UNIT / 2f + y_offset;  // position of the drawn lines on the map

// For scaling the map
float draw_x_offset = 50f;
float draw_y_offset = 50f;
float scale = 1.4f;  

// Variables added by me to create a cleaner code
int backgroundColor = color(80, 80, 80); // Color for background color of the visualization
int horizontalcolor = color(160, 255, 255); // Color for the horiztonal lines drawn on the map
int verticalcolor = color(160, 255, 255); // Color for the vertical lines drawn on the map
int informationDisplayColor = color(255, 190, 250); // Color for the information display on the top left corner of the map
int indicatorColor = color(255, 230, 0); // Color for the indicator that pinpoints the earthquake data
int legendTextSize = 30; // Text Size for drawing the legend

// Robinson projection: radicalcartography.net 
// Parallel lengths
float[] robinson_X = {1.0000f, 0.9986f, 0.9954f, 0.9900f, 0.9822f, 0.9730f, 
  0.9600f, 0.9427f, 0.9216f, 0.8962f, 0.8679f, 0.8350f, 0.7986f, 0.7597f, 
  0.7186f, 0.6732f, 0.6213f, 0.5722f, 0.5322f};
// Parallel distance from the Equator
float[] robinson_Y = {0.0000f, 0.0314f, 0.0629f, 0.0943f, 0.1258f, 0.1572f, 
  0.1887f, 0.2201f, 0.2515f, 0.2826f, 0.3132f, 0.3433f, 0.3726f, 0.4008f, 
  0.4278f, 0.4532f, 0.4765f, 0.4951f, 0.5072f};

// Two sets of data including the ArrayList<Country> and the HashMap<key,value>
ArrayList<Country> allcountries = new ArrayList();
HashMap<String, Country> countryhashmap = new HashMap(); // using country code to identify the countries
ArrayList <Earthquakes> earthquakes = new ArrayList();  // the earthquake data between 2000-2020 
Earthquakes currentearthquake = null; 
int showing = 0;    // showing the current earthquake data 

// The earthquake magnitude of each of the earthquake 
// Magnitude "0" is the default
String [] magnitude = {
  "0", "1", "2", "3", "4", "5", "6", "7", "8", "9"
};

// Using different color to show magnitude of the earthquake 
int [] magnitude_color ={
  color(50,50,50,120), // grey for default
  color(255,0,0,120), // red for magnitude 1
  color(255,125,0,120), // orange for magnitude 2 
  color(240,220,0,120), // yellow for magnitude 3
  color(0,250,20,120), // green for magnitude 4
  color(0,170,250,120), // blue for magnitude 5
  color(20,0,220,120), // indigo blue for magnitude 6
  color(140,40,255,120), // purple for magnitude 7
  color(255,10,210,120), // pink for magnitude 8
  color(75,35,0,120) // brown for magnitude 9
};

// Setting the window size
final int setupWidth = 1840;
final int setupHeight = 940;

// For setting the display window size
@Override
  public void settings() {
  size(setupWidth, setupHeight);
}

// For setting up the overall map as well as the data 
@Override
  public void setup() { 
  // Origin from Wikimedia Commons, by RedGolpe 
  // Modified by Prof. Cooper from Ritsumeikan University
  worldmap.map = loadShape(worldmap.worldmapfilename);

  // The SVG itself does not include the equator line for both vertical and horizontal
  // Below is for adding the parallel lines on the svg world map
  addParallel("equator", x_offset, equator_y, MAP_UNIT * 2 + x_offset, equator_y);

  // For mapping the intervals between the lines 
  for (int p = 3; p < robinson_X.length; p += 3) {
    addParallels(p);
  }
  // Adding Meridian (vertical) lines utilizes the Longitude 
  // In this specific program, the West is positive where in most cases, East is usually positive.
  // Drawing every 15 degrees for E and W 
  for (int longitude = 165; longitude >= -180; longitude -= 15) {
    addMeridian(longitude);
  }
  // For the position of the border of the meridians (vertical lines)
  addMeridian(170);
  addMeridian(-190);

  // Get all the earthquake names of the PShapes in the World Map
  ArrayList<String> eqnames = new ArrayList();
  for (PShape PS : worldmap.map.getChildren()) {
    eqnames.add(PS.getName());
  }

  // This earthquake data table has been modified and now includes the ISO Alpha 2 Codes
  // The purpose of adding the ISO Alpha 2 Codes is to link the earthquake.csv file to the countries-various.csv file
  // Below is for loading the country data file
  Table countrydatatable = loadTable(countrydatafile, "header");
  // The table contains the country codes for each of the country
  for (TableRow tr : countrydatatable.rows()) {
    String code = tr.getString("iso-alpha2").toLowerCase();
    float[] latitudelongitude = new float[2];
    // Getting latitude and longitude from the country data file
    latitudelongitude[0] = tr.getFloat("latitude");
    latitudelongitude[1] = tr.getFloat("longitude");
    // Getting the name of the countries 
    String Location = tr.getString("name");
    PShape shape = worldmap.map.findChild(code);
    if (shape == null) {

    } else {
      // For creating a new Country object 
      Country C = new Country(Location, code, shape);

      C.setLatitudeLongitude(latitudelongitude);
      float x = longitudeToX(latitudelongitude[0], latitudelongitude[1]);
      float y = latitudeToY(latitudelongitude[0]);
      C.setMapLocation(x, y);

      allcountries.add(C);
      countryhashmap.put(C.isocode, C);
    }
  }

  // Loading the earthquake data (earthquake.csv)
  Table eqtable = loadTable(earthquakedatafile, "header");
  for ( TableRow row : eqtable.rows() ) {
    Earthquakes eq = new Earthquakes(row);
    // Getting the X and Y position using the latitude and longitude data in the earthquake.csv file
    float x = longitudeToX(eq.LATITUDE, eq.LONGITUDE);
    float y = latitudeToY(eq.LATITUDE);
    eq.setMapLocation(x, y);
    
    // Drawing a circle for each of the earthquake data
    // Each earthquake data will have a PShape circle object located at the designated map coordinate 
    // The size of the circle defers accordingly to the earthquake's magnitude
    // The color of the circle also is decided by the magnitude of the earthquake
    eq.circle = createShape(PShape.ELLIPSE, eq.x, eq.y, eq.Magnitude*7f, eq.Magnitude*7f);
    eq.circle.setFill(magnitude_color[eq.Magnitude]); 
    eq.circle.setStroke(color(0, 0, 0, 120));
    eq.circle.setStrokeWeight(2f);
    
    // Adding the circles onto the world map
    worldmap.map.addChild(eq.circle);
    earthquakes.add(eq);
  }
  // Setting the textsize for information display
  textSize(30);
  setcurrentearthquake();
  updateMap();
}

@Override
  public void draw() {
    // 
  }
  
  
int indicno = 0;
// There are two indicators at a time, "indic0" and "indic1"
// The intersection of the two indicators will be the earthquake data 
// Wherever the indicators intersects, the information of that specific earthquake will be shown on the top right corner  
PShape addIndicator(float x1, float y1, float x2, float y2) {
  indicno = (indicno + 1) % 2;
  PShape p = worldmap.map.getChild("indicator" + indicno);
  if (p != null) {
    worldmap.map.removeChild(worldmap.map.getChildIndex(p));
  }
  // Creating the line that shows the data on the intersection
  PShape line = createShape(LINE, x1, y1, x2, y2);
  line.setStrokeWeight(6f);
  line.setStroke(indicatorColor);
  line.setName("indicator" + indicno);
  // Adding the indicator lines onto the map
  worldmap.map.addChild(line);
  return line;
}

// Drawing the horizontal lines on the world map (parallels)
PShape addParallel(String parallel, float x1, float y1, float x2, float y2) {
  PShape line = createShape(LINE, x1, y1, x2, y2);
  line.setStrokeWeight(1f);
  line.setStroke(horizontalcolor);
  line.setName(parallel);
  // Adding onto the map
  worldmap.map.addChild(line);
  return line;
}
// Adding the parallels onto the world map using the Robinson Project
void addParallels(int parallel) {
  float disty = eq_to_pole_dist * robinson_Y[parallel];
  float lengthx = robinson_X[parallel] * ten_east_x; 
  float x1 = (ten_east_x - lengthx) + x_offset;
  float x2 = (ten_east_x + lengthx) + x_offset;
  float parallel_y = equator_y - disty;
  addParallel("north" + (parallel * 5), x1, parallel_y, x2, parallel_y);
  parallel_y = equator_y + disty;
  addParallel("south" + (parallel * 5), x1, parallel_y, x2, parallel_y);
}

// Using the value for Latitude and Longitude  
// Mapping the earthquake data to the Robinson projection SVG map directly. 
// The X value requires both latitude and longitude.
float longitudeToX(float latitude, float longitude) {
  longitude *= -1f; // longitude of the data
  
  // For positioning the data (horizontally)
  int parallelAbove = Math.abs((int) (latitude / 5f)) + 1;
  float disty2 = robinson_X[parallelAbove];
  int parallelBelow = Math.abs((int) (latitude / 6f));
  float disty1 = robinson_X[parallelBelow];
  float diff = Math.abs((int) latitude) - parallelBelow * 5f;
  float distx = map(diff, 0f, 5f, disty1, disty2);

  float amount_west_10E = ((float) longitude + 10f) / 180f;

  float x_adjust = distx * ten_east_x * amount_west_10E;
  float x = ten_east_x - x_adjust + x_offset;
  return x;
}

// The Y value requires only Latitude. 
float latitudeToY(float latitude) {
  // For positioning the data (vertically)
  int parallelAbove = Math.abs((int) (latitude / 5f)) + 1;
  float disty2 = eq_to_pole_dist * robinson_Y[parallelAbove];
  int parallelBelow = Math.abs((int) (latitude / 5f));
  float disty1 = eq_to_pole_dist * robinson_Y[parallelBelow];
  float diff = Math.abs((int) latitude) - parallelBelow * 5f;
  float disty = map(diff, 0f, 5f, disty1, disty2);
  if (latitude > 0f) {
    disty *= -1.0f;
  }

  float y = equator_y + disty;
  return y;
}

// Adding the vertical lines (meridians) to the map
void addMeridian(int degreeswest) {
  // There is about a ten degree difference center vs the prime meridian
  float amount_west_10E = ((float) degreeswest + 10f) / 180f;
  PShape meridian = createShape();
  
  // Drawing the meridians 
  meridian.beginShape();
  meridian.stroke(verticalcolor);
  meridian.strokeWeight(1f);
  meridian.noFill();

  // Draw the southern hemisphere part of the meridian 
  for (int m = robinson_X.length - 1; m > 0; m--) {
    float x_adjust = robinson_X[m] * ten_east_x * amount_west_10E;
    float x = ten_east_x - x_adjust + x_offset;
    float y = equator_y + eq_to_pole_dist * robinson_Y[m];
    meridian.vertex(x, y);
  }
  // Draw the northern hemispshere part of the meridian 
  for (int m = 0; m < robinson_X.length; m++) {
    float x_adjust = robinson_X[m] * ten_east_x * amount_west_10E;
    float x = ten_east_x - x_adjust + x_offset;
    float y = equator_y - eq_to_pole_dist * robinson_Y[m];
    meridian.vertex(x, y);
  }
  
  // Adding the meridians to the world map
  meridian.endShape();
  worldmap.map.addChild(meridian);
}

// Calling an update when there is a change
public void updateMap() {

  if (currentearthquake != null) {
    background(backgroundColor);
    float x = currentearthquake.x;
    float y = currentearthquake.y;
    
    // Indicator lines showing the current earthquake data that is pointed by the intersection of the two lines
    addIndicator(0f, y, 3200f, y);
    addIndicator(x, 100f, x, 1600f);
    
    // Code for showing the information on the top left corner
    // Using push() and pop() matrix
    pushMatrix();
    scale(scale);
    translate(draw_x_offset, draw_y_offset);
    shape(worldmap.map, 0f, 0f);
    popMatrix();
    fill(informationDisplayColor);
    textSize(legendTextSize);
    text(currentearthquake.Location + " , " + currentearthquake.YEAR, 20, 70);
    // Show whether there is a tsunami warning or not
    text("Tsunami Flag: " + currentearthquake.tsunami_flag, 20, 115);
    // Circle showing the magnitude along with all the other information
    stroke(informationDisplayColor);
    fill(magnitude_color[currentearthquake.Magnitude]); 
    ellipse(30, 155, 25, 25);
    // Showing the magnitude of the earthquake data
    fill(informationDisplayColor);
    text(magnitude[currentearthquake.Magnitude], 55, 165);
    // Show information of the country code
    fill(informationDisplayColor);
    text(currentearthquake.countrycodes, 20, 210);
    
    // For LEGEND
    fill(240, 230, 250);
    stroke(0);
    strokeWeight(1);
    rect(1685, 520, 130, 400);
    // Draw the legend itself     
    textSize(20);
    fill(0);                                      
    text("Magnitude", 1700, 550);
    
    // Drawing the circles with the magnitude color as well as the text indicating the magnitude number
    // Legend is shown at the bottom right side of the visualization window
    textSize(legendTextSize);   
    pushMatrix(); 
      for (int i = 0; i<magnitude.length; i++) {
        fill(magnitude_color[i]);
        ellipse(1720, 590, 20f, 20f);
        text(magnitude[i], 1770, 600);  // position is set
        // move down each label without a counter 
        translate(0, legendTextSize*1.1f);
      }
     popMatrix();
     
     // Legend for tectonic plates border
     
     strokeWeight(4);
     stroke(180);
     line(1570, 100, 1600, 100);
     textSize(20);
     fill(255);
     text("Tectonic Plate Border", 1620, 105);
     text("Ring of Fire", 1620, 135);
     stroke(255, 0, 0, 200);
     line(1570, 130, 1600, 130);
     
     // Drawing out and highlighting RING OF FIRE (earthquake frequently happens)
     noFill();
     stroke(255, 0, 0, 200);
     strokeWeight(3);
     // RING OF FIRE (left side of the map)
     beginShape();
     curveVertex(130, 220); //Starting point
     curveVertex(130, 220);
     curveVertex(280, 190); 
     curveVertex(285, 240);
     curveVertex(280, 330);
     curveVertex(380, 430); 
     curveVertex(430, 440);
     curveVertex(420, 470);
     curveVertex(430, 510); 
     curveVertex(460, 550);
     curveVertex(480, 650);
     curveVertex(480, 680);
     curveVertex(500, 710);
     curveVertex(550, 750);
     curveVertex(560, 770);
     curveVertex(560, 770); //Starting point
     endShape();
     
     // RING OF FIRE (right side of the map)
     beginShape();
     curveVertex(1550, 220); //Starting point
     curveVertex(1550, 220);
     curveVertex(1500, 230);
     curveVertex(1460, 210);
     curveVertex(1420, 200);
     curveVertex(1410, 270);
     
     curveVertex(1400, 290);
     curveVertex(1380, 330);
     curveVertex(1340, 380);
     curveVertex(1370, 430);
     curveVertex(1390, 460);
     curveVertex(1390, 460);
     
     curveVertex(1390, 460);
     curveVertex(1420, 470);
     curveVertex(1450, 480);
     curveVertex(1480, 480);
     curveVertex(1500, 480);
     curveVertex(1560, 510);
     curveVertex(1570, 550);
     curveVertex(1580, 570);
     curveVertex(1610, 540);
     curveVertex(1620, 570);
     curveVertex(1610, 610);
     curveVertex(1550, 670);
     curveVertex(1510, 690);
     curveVertex(1460, 670); 
     curveVertex(1430, 710);
     curveVertex(1420, 770);
     curveVertex(1420, 770); //Ending point
     endShape();
     
     // Drawing settings for the tectonic plates 
     noFill();
     stroke(180, 180, 180, 200);
     strokeWeight(1);
     // Pacific Plate
     // Includes borders with North American Plate, Cocos Plate, and Nazca Plate
     beginShape();
     curveVertex(130, 220); //Starting point
     curveVertex(130, 220);
     curveVertex(280, 190); 
     curveVertex(285, 240);
     curveVertex(280, 330);
     curveVertex(380, 430); 
     curveVertex(430, 440);
     curveVertex(420, 470);
     curveVertex(430, 510); //South America 
     curveVertex(460, 550);
     curveVertex(480, 650);
     curveVertex(480, 680);
     curveVertex(500, 710);
     curveVertex(550, 750);
     curveVertex(560, 770);
     curveVertex(560, 770); //Ending point
     endShape();

     // South American Plate 
     // Includes borders with African Plate and the Caribbean Plate
     beginShape();
     curveVertex(342, 400); //Starting point
     curveVertex(342, 400);
     curveVertex(370, 410);
     curveVertex(410, 365);
     curveVertex(500, 390);
     curveVertex(580, 395);
     curveVertex(650, 450);
     curveVertex(720, 470);
     curveVertex(730, 650);
     curveVertex(770, 740);
     curveVertex(770, 740); //Ending point
     endShape();
     
     // African Plate
     // Includes borders with Australian, Indian, Arabian, and Eurasian Plates
     beginShape();
     curveVertex(560, 770); //Starting point
     curveVertex(560, 770);
     curveVertex(660, 770);
     curveVertex(770, 740);
     curveVertex(900, 720);
     curveVertex(930, 725);
     curveVertex(960, 680);
     curveVertex(1110, 600);
     curveVertex(1120, 480);
     curveVertex(1100, 450);
     curveVertex(1080, 420);
     curveVertex(1000, 410);
     curveVertex(980, 400);
     curveVertex(970, 380);
     curveVertex(960, 360); //Gap between Africa & Middle East
     curveVertex(940, 310); 
     curveVertex(890, 300);
     curveVertex(870, 290);
     curveVertex(850, 280); 
     curveVertex(830, 290); 
     curveVertex(800, 300);
     curveVertex(670, 280);
     curveVertex(610, 320);
     curveVertex(580, 395);
     curveVertex(580, 395); //Ending point
     endShape();
     
     // Australian Plate (entire Top)
     // Includes borders with Indian, Eurasian, Phillipine Sea, and Pacific Plates
     beginShape();
     curveVertex(1120, 480); //Starting point
     curveVertex(1120, 480);
     curveVertex(1180, 490);
     curveVertex(1220, 420);
     curveVertex(1230, 390); 
     curveVertex(1240, 450);
     curveVertex(1250, 480);
     curveVertex(1290, 510);
     curveVertex(1340, 500);
     curveVertex(1360, 490); //Indonesian main island
     curveVertex(1390, 460);
     curveVertex(1420, 470);
     curveVertex(1450, 480);
     curveVertex(1480, 480);
     curveVertex(1500, 480);
     curveVertex(1560, 510);
     curveVertex(1570, 550);
     curveVertex(1580, 570);
     curveVertex(1610, 540);
     curveVertex(1620, 570);
     curveVertex(1610, 610);
     curveVertex(1550, 670);
     curveVertex(1510, 690);
     curveVertex(1460, 670); //New zealand
     curveVertex(1430, 710);
     curveVertex(1420, 770);
     curveVertex(1420, 770); //Ending point
     endShape();
     
     // Australian Plate (bottom)
     beginShape();
     curveVertex(1110, 600); //Starting point
     curveVertex(1110, 600);
     curveVertex(1200, 690);
     curveVertex(1320, 710);
     curveVertex(1420, 770);
     curveVertex(1420, 770); //Ending point
     endShape();
     
     // Eurasian Plate
     // Includes borders with Phillipine Sea and North American Plates
     beginShape();
     curveVertex(1390, 460); //Starting point
     curveVertex(1390, 460);
     curveVertex(1370, 430);
     curveVertex(1340, 380);
     curveVertex(1380, 330);
     curveVertex(1400, 290);
     curveVertex(1410, 250);
     curveVertex(1350, 210);
     curveVertex(1280, 170);
     curveVertex(1180, 150);
     curveVertex(1160, 120);
     curveVertex(1100, 110);
     curveVertex(950, 95);
     curveVertex(800, 100);
     curveVertex(780, 110); // Reach Greenland
     curveVertex(810, 120);
     curveVertex(790, 130);
     curveVertex(770, 140);
     curveVertex(750, 160);
     curveVertex(700, 180);
     curveVertex(670, 190);
     curveVertex(650, 210);
     curveVertex(660, 215);
     curveVertex(680, 230);
     curveVertex(690, 250);
     curveVertex(670, 280);
     curveVertex(670, 280); //Ending point
     endShape();
     
     // Cocos Plate
     // Includes borders with Pacific, Nazca, and the Caribbean Plates
     beginShape();
     curveVertex(280, 330); //Starting point
     curveVertex(280, 330);
     curveVertex(280, 400);
     curveVertex(290, 410);
     curveVertex(295, 440);
     curveVertex(295, 460);
     curveVertex(340, 460);
     curveVertex(360, 470);
     curveVertex(380, 475);
     curveVertex(400, 460);
     curveVertex(430, 440);
     curveVertex(430, 440); //Ending point
     endShape();
     
     // Nazca Plate
     // Includes borders with South American, Pacific, and Cocos Plates
     beginShape();
     curveVertex(293, 460); //Starting point
     curveVertex(293, 460);
     curveVertex(293, 500);
     curveVertex(270, 510);
     curveVertex(260, 580);
     curveVertex(270, 670);
     curveVertex(300, 680);
     curveVertex(380, 675);
     curveVertex(400, 690);
     curveVertex(430, 700);
     curveVertex(450, 690);
     curveVertex(480, 700);
     curveVertex(495, 700);
     curveVertex(495, 700); //Ending point
     endShape();
     
     // Pacific Plate (bottom)
     beginShape();
     curveVertex(270, 670); //Starting point
     curveVertex(270, 670);
     curveVertex(270, 720);
     curveVertex(250, 720);
     curveVertex(235, 750);
     curveVertex(220, 770);
     curveVertex(220, 770); //Ending point
     endShape();
     
     // Caribbean Plate
     // Includes borders with North and South American, and Cocos Plates
     beginShape();
     curveVertex(430, 440); //Starting point
     curveVertex(430, 440);
     curveVertex(450, 420);
     curveVertex(470, 410);
     curveVertex(500, 430);
     curveVertex(510, 390);
     curveVertex(500, 390); //Ending point
     endShape();
     
     // Juan de Fuca Plate
     // Includes borders with North American and Pacific Plates
     beginShape();
     curveVertex(285, 230); //Starting point
     curveVertex(285, 230);
     curveVertex(260, 250);
     curveVertex(260, 270);
     curveVertex(250, 285);
     curveVertex(245, 295);
     curveVertex(273, 310);
     curveVertex(273, 310); //Ending point
     endShape();
     
     // Arabian Plate
     // Includes borders with Eurasian, Indian, and African Plates
     beginShape();
     curveVertex(900, 300); //Starting point
     curveVertex(900, 300);
     curveVertex(935, 270);
     curveVertex(960, 280);
     curveVertex(1000, 290);
     curveVertex(1050, 350);
     curveVertex(1100, 340);
     curveVertex(1130, 390);
     curveVertex(1095, 440);
     curveVertex(1095, 440); //Ending point
     endShape();
     
     // Indian Plate
     // Includes borders with African, Arabian, Eurasian, and Australian Plates
     beginShape();
     curveVertex(1080, 345); //Starting point
     curveVertex(1080, 345);
     curveVertex(1100, 300);
     curveVertex(1130, 300);
     curveVertex(1140, 330);
     curveVertex(1170, 320);
     curveVertex(1200, 320);
     curveVertex(1245, 310);
     curveVertex(1230, 330);
     curveVertex(1240, 350);
     curveVertex(1230, 390);
     curveVertex(1230, 390); //Ending point
     endShape();
     
     // Philliine Sea Plate
     // Includes borders with Eurasian and Pacific Plates
     beginShape();
     curveVertex(1390, 460); //Starting point
     curveVertex(1390, 460);
     curveVertex(1460, 410); //Outmost point
     curveVertex(1440, 370);
     curveVertex(1430, 350);
     curveVertex(1410, 320); //Near Japan
     curveVertex(1405, 280);
     curveVertex(1405, 280); //Ending point
     endShape();
     
     // Pacific Plate (Right side of the map)
     beginShape();
     curveVertex(1410, 270); //Starting point
     curveVertex(1410, 270);
     curveVertex(1420, 200); 
     curveVertex(1460, 210);
     curveVertex(1500, 230);
     curveVertex(1550, 220);
     curveVertex(1550, 220); //Ending point
     endShape();
     
     // Scotia Plate
     // Between South American and Antartic Plates
     beginShape();
     curveVertex(525, 730); //Starting point
     curveVertex(525, 730);
     curveVertex(600, 720);
     curveVertex(700, 720);
     curveVertex(690, 750);
     curveVertex(680, 766);
     curveVertex(680, 766); //Ending point
     endShape();
     
     // Minor fix
     beginShape();
     curveVertex(1420, 770); //Starting point
     curveVertex(1420, 770);
     curveVertex(1440, 780);
     curveVertex(1495, 760);
     curveVertex(1495, 760); //Ending point
     endShape();
  }
}

// For changing the data display
// Uses the "," and "." key on the keyboard
// Press "q" to quite the program
// Code Reference: class material EndangeredLanguages_190604a by Prof. Cooper
@Override
  public void keyPressed() {
  switch (key) {
  case CODED:
    break;
  case ' ':
  case '.':
    showing++;
    if (showing >= earthquakes.size()) {
      showing = 0;
    }
    setcurrentearthquake();
    updateMap();
    break;
  case ',':
    showing--;
    if (showing < 0 ) {
      showing = earthquakes.size()-1;
    } 
    setcurrentearthquake();
    updateMap();
    break;
  case 'q':
    // Press q to exit the program
    exit();
    break;
    
  default:
    break;
  }
}


// Showing the current earthquake for information display on the top left corner
public void setcurrentearthquake() {
  selectEarthquake(showing);
}

// Getting the current showing earthquake's magnitude
public void selectEarthquake(int earthquake_magnitude) {
  currentearthquake = earthquakes.get(earthquake_magnitude);
}

// Holds all the data used for the earthquake data
class Earthquakes {
  int YEAR = 0; 
  int Magnitude = 0;
  float LATITUDE = 0.0f;
  float LONGITUDE = 0.0f;
  float x = 0.0f;
  float y = 0.0f;
  String Location;
  String countrycodes;
  String tsunami_flag;
  PShape circle = null;

  Earthquakes( TableRow tr ) {
    YEAR = tr.getInt("YEAR");
    Magnitude = tr.getInt("EQ_PRIMARY");
    LATITUDE = tr.getFloat("LATITUDE");
    LONGITUDE = tr.getFloat("LONGITUDE");
    Location = tr.getString("LOCATION_NAME");
    countrycodes = tr.getString("iso-alpha2");
    tsunami_flag = tr.getString("FLAG_TSUNAMI");
  }

  public void setMapLocation(float x_on_map, float y_on_map) {
    x = x_on_map;
    y = y_on_map;
  }
}

// Country class
// Holds all the data used in the SVG world map
class Country {

  float center_x = 0.0f;
  float center_y = 0.0f;
  float latitude = 0.0f;
  float longitude = 0.0f;
  PShape map = null;

  String nameLocation = "";
  String isocode = ""; 

  public Country(String fullname, String iso_alpha2, PShape countrymap) {
    nameLocation = fullname;
    isocode = iso_alpha2;
    map = countrymap;
  }

  // Map Location
  public void setMapLocation(float x, float y) {
    center_x = x;
    center_y = y;
  }
  
  // Setting longitude and latitude
  public void setLatitudeLongitude(float[] latitudelongitude) {
    latitude = latitudelongitude[0];
    longitude = latitudelongitude[1];
  }
}
