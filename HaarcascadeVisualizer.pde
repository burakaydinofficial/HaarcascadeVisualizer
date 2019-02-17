/*********************************************************************************
 * Haar Feature Visualizer
 *
 * Summary: Creates a visual reference for haar features
 * Author: Adam Harvey / http://ahprojects.com
 * License: Free.99, permissing
 * Tested with Processing 2.0a4
 * Warning: you need the old XML library
 * Using XML instead of XMLElement throws errors with getChild()
 ********************************************************************************/

/*********************************************************************************
 *
 * Notes
 * Only visualizes the first nodes, some trees have several nodes and add'l nodes are not included
 * There are some things that it does not visualize yet such as threshold and right/left values
 * Improvements welcome. Contact me at http://ahprojects.com/about for suggestions, comments, ideas
 *
 ********************************************************************************/


// ------------------------------------------------------------------------
// START Editable Parameters
// Cascade file
String cascadeFile = "haarcascade_frontalface_default.xml";
String referenceImagePath = "face.jpg";

// Choose amount of white space around the image
int margin = 0;
// Color of the image background
color imgBgColor = color(200);

// Choose draw mode
// 0 = Contact sheet, showing first haar feature of each stage
// 1 = All haar features, one file per stage in folder named after xml file
int drawMode = 0;

// Open files after rendered?
boolean openFiles = false;

// END Editable Parameters
// ------------------------------------------------------------------------

//import processing.xml.*;
import java.awt.Rectangle;
//import interfascia.*;
import controlP5.*;
ControlP5 cp5;
// Interface elements


PFont font1, font2;

// Logic
boolean doProcess;
boolean hasErrors = false;
String statusMsg = "";
int idCur;

// GUI

int marginL = 40;
int marginT = 60;

// Graphics
int[] sampleSize = new int[2];
int minSize = 20;
PImage img, resizedImg;
int rows, cols;
int imgSize;

// File I/O
ArrayList stages;
float stageScale;
String[] xmlFiles;
int textAlpha = 255;
int waitCount;
int waitCountMax = 3;
String path; // sketch path

void setup() {
  size(500, 800,P2D);
  PFont font = createFont("arial", 20);  
  cp5 = new ControlP5(this);

  println("[main] using cascade: " + cascadeFile);
 

  cp5.addButton("bFirst")
      .setPosition(marginL, marginT+50)
        .setSize(150, 19).setCaptionLabel("RENDER FIRST")
          ;

  cp5.addButton("bAll")
      .setPosition(marginL+220, marginT+50)
        .setSize(200, 19).setCaptionLabel("RENDER ALL STAGES")
          ;





  path = sketchPath; // an environment variable

  // Replace with your face or use Lena
  img = loadImage(referenceImagePath);
  imgSize = img.width;
  rows = height/imgSize;
  cols = width/imgSize;

  smooth();


  // (text, x, y, width, height)


  font1 = createFont("Helvetica-Bold", 30);
  font2 = createFont("Helvetica", 11);
}

void draw() {

  // Catch Process
  // Need to do this to keep draw() loop alive
  checkForProcess();

  // Draw
  background(255);

  textFont(font1);
  fill(20);
  int yPos = marginT;
  int xPos = marginL;
  text("Haarcascade Visualizer", xPos, yPos);
  yPos+= 20;

  textFont(font2);
  fill(60);
  text("\"" + cascadeFile + "\"", xPos, yPos);

  fill(255, 0, 0, textAlpha);
  yPos += 15;
  text(statusMsg, xPos, yPos);

  if (textAlpha > 0) textAlpha-=2;

  fill(80);
  textFont(font2);

  if (resizedImg != null && resizedImg.width > 0) {
    image(resizedImg, marginL, 200);
  }

  if (doProcess && !hasErrors) {
    if (waitCount < waitCountMax) {
      waitCount++;
    } 
    else {
      waitCount = 0;
      doProcessing();
    }
  }
}


void checkForProcess() {
  if (doProcess) {
    textAlpha = 255;
    String name = cascadeFile;
    String path = sketchPath +"/";
    File f = new File(dataPath(cascadeFile));
    if (f.exists() && name.length() > 0)
    {
      hasErrors = false;
      statusMsg = "Rendering. This could take several minutes.";
    } 
    else {
      hasErrors = true;
      doProcess = false;
      statusMsg = "File not found.";
    }
  }
}

public void  bAll(){
  drawMode = 1;
    doProcess = true;
}
public void  bFirst(){
  drawMode = 0;
    doProcess = true;
}

void doProcessing() {
  String name = cascadeFile;
  String path = sketchPath +"/";
  println(name);
  stages = doLoadXML(name);
  String[] pieces = split(name, '.');
  name = pieces[0];

  if (drawMode == 0)
  {
    println("[main] Rendering preview for "+name);
    renderPreviews(name);
  } 
  else if (drawMode == 1)
  {
    println("[main] Rendering stages for "+name);
    println("[main] Please wait. This may take around a minute to process");
    renderStages(name);
  } 
  statusMsg = "Done writing files.";
  doProcess = false;
  println("\n[main] Done.");
}

// Renders only the first tree from each stage
// Useful for creating a preview and testing wheter a file is valid
void renderPreviews(String name) {
  println("[main][renderPreviews]["+name+"]");
  imgSize = img.width;//calucated from XML file
  minSize = sampleSize[0];
  int renderWidth = 680;
  int renderCols = ceil(renderWidth/(imgSize+margin));
  renderWidth = renderCols*(imgSize+margin)+(margin);
  int renderHeight = (ceil(stages.size()/(float)renderCols)*(imgSize+margin))+(margin);
  PGraphics container = createGraphics(renderWidth, renderHeight, P2D);
  container.beginDraw();
  container.background(imgBgColor);
  container.endDraw();
  stageScale = (float)imgSize/(float)minSize;

  for (int i=0;i<stages.size();i++) {
    container.pushMatrix();
    int ypos = floor((imgSize+margin)*(ceil(i/renderCols)))+margin;
    int xpos = (imgSize+margin)*(i%renderCols)+margin;
    container.beginDraw();
    container.translate(xpos, ypos);
    container.image(img, 0, 0);
    container.filter(GRAY);
    // Render stage
    Stage stage = (Stage) stages.get(i);
    for (int j=0;j<stage.getNumItems();j++) {//get all trees in this stage
      if (j>0)continue;//skips extra trees in the stage
      Tree tree = stage.getTree(j);
      PGraphics featuresImg = tree.render(imgSize, stageScale, 1);
      container.image(featuresImg, 0, 0);
    } 
    container.endDraw();
    container.popMatrix();
  }
  String filename = name +".tif";
  container.save(filename);
  resizedImg = loadImage(filename);
  resizedImg.resize(width-100, 0);
  println("[main] Saved filename: " + filename );

  //open(sketchPath + "/.");
}

// Render every stage of every file
void renderStages(String name) {
  imgSize = img.width;//calucated from XML file
  minSize = sampleSize[0];
  stageScale = (float)imgSize/(float)minSize;
  int renderWidth = 1024;
  println("stages: " + stages.size() );
  for (int i=0;i<stages.size();i++) {
    Stage stage = (Stage) stages.get(i);
    int renderCols = ceil(renderWidth/(imgSize+margin));
    renderWidth = renderCols*(imgSize+margin)+(margin);
    int renderHeight = (ceil(stage.getNumItems()/(float)renderCols)*(imgSize+margin))+(margin);
 
    PGraphics container = createGraphics(renderWidth, renderHeight, P2D);
    container.beginDraw();
    container.background(imgBgColor);
    container.endDraw();
    //println("trees in this stage" + stage.getNumItems() );
    // Render stage
    for (int j=0;j<stage.getNumItems();j++) {//get all trees in this stage      
      Tree tree = stage.getTree(j);
     // println("[main] Processing tree # " + j + " in stage " + (i+1));
      statusMsg = "[main] Processing tree # " + j + " in stage " + (i+1);
      redraw();
      PGraphics featuresImg = tree.render(imgSize, stageScale, 1);
      int ypos = floor((imgSize+margin)*(ceil(j/renderCols)))+margin;
      int xpos = (imgSize+margin)*(j%renderCols)+margin;
      container.pushMatrix();
      container.beginDraw();
      container.translate(xpos, ypos);
      container.image(img, 0, 0);
      container.filter(GRAY);
      container.image(featuresImg, 0, 0);
      container.endDraw();
      container.popMatrix();
      featuresImg.clear();
      featuresImg=null;


     // delay(500);
    }

    println("[main] Rendered stage " + (i+1));

    String filename =  "renders/"+name+"/stage_"+i+".tif";
    container.save(filename);
    
    container.clear();
    println("[main] Saved filename: " + filename );
    container=null;
    System.gc();
  }

  // Open folder
  open(sketchPath + "/" + name + "/.");
}
