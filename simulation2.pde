class Grid {
  float squareSize;
  int gridWidth;
  int gridHeight;
  String rule;
  int smokeDecay;
  int[][] grid;
  int[][] newGrid;
  int[][] smokeTimes;
  float[][] waterGrid;
  float[][] waterPressure;
  float[][] newWaterGrid;
  int generation;
  int[] B;
  int[] S;
  float waterTreshold;
  float flow;
  float remaning_mass;
  float MinFlow = 0.5;
  float MaxSpeed = 1;
  
  Grid(float squareSize, int gridWidth, int gridHeight, String rule, int smokeDecay, float waterTreshold) {
    this.squareSize = squareSize;
    this.gridWidth = gridWidth;
    this.gridHeight = gridHeight;
    this.rule = rule;
    this.smokeDecay = smokeDecay;
    this.waterTreshold = waterTreshold;
    this.grid = new int[this.gridHeight][];
    this.newGrid = new int[this.gridHeight][];
    this.waterGrid = new float[this.gridHeight][];
    this.waterPressure = new float[this.gridHeight][];
    this.newWaterGrid = new float[this.gridHeight][];
    this.smokeTimes = new int[gridHeight][];
    this.generation = 0;
    this.parseRule(this.rule);
    this.flow = 0.;
  }
  
  void printGrid() {
    for (int i = 0; i < this.gridHeight; i++) {
      for (int j = 0; j < this.gridWidth; j++) {
        print(this.grid[i][j] + " ");
      }
      println();
    }
    println();
  }
  
  void parseRule(String rule) {
    String[] parts = split(rule, '/');
    String bPart = parts[0].substring(1);
    String sPart = parts[1].substring(1);
    
    this.B = new int[bPart.length()];
    for (int i = 0; i < bPart.length(); i++) {
      this.B[i] = Integer.parseInt(bPart.charAt(i) + "");
    }
    
    this.S = new int[sPart.length()];
    for (int i = 0; i < sPart.length(); i++) {
      this.S[i] = Integer.parseInt(sPart.charAt(i) + "");
    }
  }
  
  boolean containsElement(int[] array, int value) {
    for (int i = 0; i < array.length; i++) {
      if (array[i] == value) {
        return true;
      }
    }
    return false; 
  }
  float get_stable_state_b ( float total_mass ){
    if ( total_mass <= 1 ){
      return 1;
    } else if ( total_mass < 2*1 + this.waterTreshold ){
      return (1*1 + total_mass*this.waterTreshold)/(1 + this.waterTreshold);
    } else {
      return (total_mass + this.waterTreshold)/2;
    }
  }
  
  void updateNewGrid() {
    for (int i = 0; i < this.grid.length; i++) {
      for (int j = 0; j < this.grid[i].length; j++) {
        this.newGrid[i][j] = this.grid[i][j];
      }
    }
  }
  
  void updateGrid() {
    for (int i = 0; i < this.grid.length; i++) {
      for (int j = 0; j < this.grid[i].length; j++) {
        this.grid[i][j] = this.newGrid[i][j];
      }
    }
  }
  
  boolean availableSpace(int i, int j) {
    if (j-1 >= 0 && (this.newGrid[i][j-1] == 0 || (this.newGrid[i][j-1] == 7 && this.waterGrid[i][j-1] < 1. + this.waterTreshold))) return true;
    if (j+1 < this.gridWidth && (this.newGrid[i][j+1] == 0 || (this.newGrid[i][j+1] == 7 && this.waterGrid[i][j+1] < 1. + this.waterTreshold))) return true;
    return false;
  }
  
  void updateSand(int i, int j) {
    if (i+1 < this.gridHeight && this.newGrid[i+1][j] == 0) {
      this.newGrid[i][j] = 0;
      this.newGrid[i+1][j] = 2;
    }
    else if (i+1 < this.gridHeight && j+1 < this.gridWidth && j-1 >= 0 && this.newGrid[i+1][j-1] == 0 && this.newGrid[i+1][j+1] == 0) {
      int choice = (int)random(2);
      if (choice == 0) {
        this.newGrid[i][j] = 0;
        this.newGrid[i+1][j-1] = 2;
      } else {
        this.newGrid[i][j] = 0;
        this.newGrid[i+1][j+1] = 2;
      }
    }
    else if (i+1 < this.gridHeight && j-1 >= 0 && this.newGrid[i+1][j-1] == 0) {
      this.newGrid[i][j] = 0;
      this.newGrid[i+1][j-1] = 2;
    }
    else if (i+1 < this.gridHeight && j+1 < this.gridWidth && this.newGrid[i+1][j+1] == 0) {
      this.newGrid[i][j] = 0;
      this.newGrid[i+1][j+1] = 2;
    }
    else if (i+1 < this.gridHeight && this.newGrid[i+1][j] == 7) {
      this.displaceWater(i+1, j);
      this.newGrid[i][j] = 0;
    }
    else if (i+1 < this.gridHeight && j+1 < this.gridWidth && j-1 >= 0 && this.newGrid[i+1][j-1] == 7 && this.newGrid[i+1][j+1] == 7) {
      int choice = (int)random(2);
      if (choice == 0) {
        this.displaceWater(i+1, j+1);
      }
      else {
        this.displaceWater(i+1, j-1);
      }
      this.newGrid[i][j] = 0;
    }
    else if (i+1 < this.gridHeight && j-1 >= 0 && this.newGrid[i+1][j-1] == 7) {
      this.displaceWater(i+1, j-1);
      this.newGrid[i][j] = 0;
    }
    else if (i+1 < this.gridHeight && j+1 < this.gridWidth && this.newGrid[i+1][j+1] == 7) {
      this.displaceWater(i+1, j+1);
      this.newGrid[i][j] = 0;
    }
    
  }
  
  void displaceWater(int i, int j) {
      this.newGrid[i][j] = 2;
      
      if (i+1 < this.gridHeight && this.newGrid[i+1][j] == 7) {
        float waterTransfer = (1. + this.waterTreshold) - this.waterGrid[i+1][j];
        if (waterTransfer <= this.newGrid[i][j]) {
          this.newWaterGrid[i+1][j] += waterTransfer;
          this.newWaterGrid[i][j] -= waterTransfer;
        }
        else {
          this.newWaterGrid[i+1][j] += this.waterGrid[i][j];
          this.newWaterGrid[i][j] = 0;
        }
      }
      
      if (this.newWaterGrid[i][j] == 0) return;
      
      
      
      if ((j-1 >= 0 && this.newGrid[i][j-1] == 7) && (j+1 < this.gridWidth && this.newGrid[i][j+1] == 7)) {
         float waterTransfer = (this.waterGrid[i][j+1] + this.waterGrid[i][j-1] + this.waterGrid[i][j])/2;
         if (waterTransfer > 1. + this.waterTreshold) {
           this.newWaterGrid[i][j+1] = 1. + this.waterTreshold;
           this.newWaterGrid[i][j-1] = 1. + this.waterTreshold;
         } else {
           this.newWaterGrid[i][j+1] = waterTransfer;
           this.newWaterGrid[i][j-1] = waterTransfer;
         }
         this.newWaterGrid[i][j] = 0.;
      }
      else if (j-1 >= 0 && this.newGrid[i][j-1] == 7) {
        float waterTransfer = (1. + this.waterTreshold) - this.waterGrid[i][j-1];
        if (waterTransfer <= this.newGrid[i][j]) {
          this.newWaterGrid[i][j-1] += waterTransfer;
          this.newWaterGrid[i][j] -= waterTransfer;
        }
        else {
          this.newWaterGrid[i][j-1] += this.waterGrid[i][j];
          this.newWaterGrid[i][j] = 0;
        }
      }
      else if (j+1 < this.gridWidth && this.newGrid[i][j+1] == 7) {
        float waterTransfer = (1. + this.waterTreshold) - this.waterGrid[i][j+1];
        if (waterTransfer <= this.newGrid[i][j]) {
          this.newWaterGrid[i][j+1] += waterTransfer;
          this.newWaterGrid[i][j] -= waterTransfer;
        }
        else {
          this.newWaterGrid[i][j+1] += this.waterGrid[i][j];
          this.newWaterGrid[i][j] = 0;
        }
      }
      this.newWaterGrid[i][j] = 0.;
  }
  
  void updateWood(int i, int j) {
    if (i-1 >= 0 && this.newGrid[i-1][j] == 4) this.newGrid[i][j] = 4;
    else if (i-1 >= 0 && j-1 >= 0 && this.newGrid[i-1][j-1] == 4) this.newGrid[i][j] = 4;
    else if (i-1 >= 0 && j+1 < this.gridWidth && this.newGrid[i-1][j+1] == 4) this.newGrid[i][j] = 4;
    if (i+1 < this.gridHeight && this.newGrid[i+1][j] == 4) this.newGrid[i][j] = 4;
    else if (i+1 < this.gridHeight && j-1 >= 0 && this.newGrid[i+1][j-1] == 4) this.newGrid[i][j] = 4;
    else if (i+1 < this.gridHeight && j+1 < this.gridWidth && this.newGrid[i+1][j+1] == 4) this.newGrid[i][j] = 4;
    else if (j-1 >= 0 && this.newGrid[i][j-1] == 4) this.newGrid[i][j] = 4;
    else if (j+1 < this.gridWidth && this.newGrid[i][j+1] == 4) this.newGrid[i][j] = 4;
    else if (i+1 < this.gridHeight && this.newGrid[i+1][j] == 0) {
      this.newGrid[i][j] = 0;
      this.newGrid[i+1][j] = 3;
    }
    else if (i-1 >= 0 && j+1 < this.gridWidth && j-1 >= 0 && this.newGrid[i][j-1] == 7 && this.newGrid[i][j+1] == 7 && this.newGrid[i-1][j] == 0) {
      float waterTransfer = (this.newWaterGrid[i][j-1] + this.newWaterGrid[i][j-1])/3;
      this.newGrid[i-1][j] = 3;
      this.newGrid[i][j] = 7;
      this.newWaterGrid[i][j] = waterTransfer;
      this.newWaterGrid[i][j-1] = waterTransfer;
      this.newWaterGrid[i][j+1] = waterTransfer;
    }
    else if (i-1 >= 0 && j-1 >= 0 && this.newGrid[i][j-1] == 7 && this.newGrid[i-1][j] == 0) {
      float waterTransfer = this.newWaterGrid[i][j-1]/2;
      this.newGrid[i-1][j] = 3;
      this.newGrid[i][j] = 7;
      this.newWaterGrid[i][j] = waterTransfer;
      this.newWaterGrid[i][j-1] = waterTransfer;
    }
    else if (i-1 >= 0 && j+1 < this.gridWidth && this.newGrid[i][j+1] == 7 && this.newGrid[i-1][j] == 0) {
      float waterTransfer = this.newWaterGrid[i][j+1]/2;
      this.newGrid[i-1][j] = 3;
      this.newGrid[i][j] = 7;
      this.newWaterGrid[i][j] = waterTransfer;
      this.newWaterGrid[i][j+1] = waterTransfer;
    } else if (i - 1 >= 0 && this.newGrid[i-1][j] == 7) {
      this.newGrid[i-1][j] = 3;
      this.newGrid[i][j] = 7;
      this.newWaterGrid[i][j] = this.newWaterGrid[i-1][j];
      this.newWaterGrid[i-1][j] = 0;
    }
  }
  
  void updateFire(int i, int j) {
    if (i+1 < this.gridHeight && this.newGrid[i+1][j] == 0) {
      if ((j-1 >= 0 && this.newGrid[i+1][j-1] == 0) && (j+1 < this.gridHeight && this.newGrid[i+1][j+1] == 0)) {
        int choice = (int)random(3);
        if (choice == 0) {
          this.newGrid[i][j] = 0;
          this.newGrid[i+1][j] = 4;
        }
        else if (choice == 1) {
          this.newGrid[i][j] = 0;
          this.newGrid[i+1][j-1] = 4;
        }
        else {
          this.newGrid[i][j] = 0;
          this.newGrid[i+1][j+1] = 4;
        }
      }
      else if (j-1 >= 0 && this.newGrid[i+1][j-1] == 0) {
        int choice = (int)random(2);
        if (choice == 0) {
          this.newGrid[i][j] = 0;
          this.newGrid[i+1][j] = 4;
        }
        else {
          this.newGrid[i][j] = 0;
          this.newGrid[i+1][j-1] = 4;
        }
      }
      else if (j+1 < this.gridHeight && this.newGrid[i+1][j+1] == 0) {
        int choice = (int)random(2);
        if (choice == 0) {
          this.newGrid[i][j] = 0;
          this.newGrid[i+1][j] = 4;
        }
        else {
          this.newGrid[i][j] = 0;
          this.newGrid[i+1][j+1] = 4;
        }
      }
      else {
        this.newGrid[i][j] = 0;
        this.newGrid[i+1][j] = 4;
      }
    }
    else if ((i+1 < this.gridHeight && (this.newGrid[i+1][j] == 1 || this.newGrid[i+1][j] == 2 || this.newGrid[i+1][j] == 5 || this.newGrid[i+1][j] == 6 || this.newGrid[i+1][j] == 7)) || i == this.gridHeight - 1) {
      this.newGrid[i][j] = 5;
      this.smokeTimes[i][j] = this.smokeDecay;
    }
    else if (i+1 < this.gridHeight && this.newGrid[i+1][j] == 3) {
      this.newGrid[i][j] = 6;
      this.smokeTimes[i][j] = this.smokeDecay;
    } 
  }
  
  void updateSmoke(int i, int j, int type) {
    this.smokeTimes[i][j]--;
    if (this.smokeTimes[i][j] == 0) {
      this.newGrid[i][j] = 0;
    }
    else if (i-1 >= 0 && this.newGrid[i-1][j] == 0) {
      if ((j-1 >= 0 && this.newGrid[i-1][j-1] == 0) && (j+1 < this.gridHeight && this.newGrid[i-1][j+1] == 0)) {
        int choice = (int)random(3);
        if (choice == 0) {
          this.newGrid[i][j] = 0;
          this.newGrid[i-1][j] = type;
          
          this.smokeTimes[i-1][j] = this.smokeTimes[i][j];
          this.smokeTimes[i][j] = 0;
        }
        else if (choice == 1) {
          this.newGrid[i][j] = 0;
          this.newGrid[i-1][j-1] = type;
          
          this.smokeTimes[i-1][j-1] = this.smokeTimes[i][j];
          this.smokeTimes[i][j] = 0;
        }
        else {
          this.newGrid[i][j] = 0;
          this.newGrid[i-1][j+1] = type;
          
          this.smokeTimes[i-1][j+1] = this.smokeTimes[i][j];
          this.smokeTimes[i][j] = 0;
        }
      }
      else if (j-1 >= 0 && this.newGrid[i-1][j-1] == 0) {
        int choice = (int)random(2);
        if (choice == 0) {
          this.newGrid[i][j] = 0;
          this.newGrid[i-1][j] = type;
          
          this.smokeTimes[i-1][j] = this.smokeTimes[i][j];
          this.smokeTimes[i][j] = 0;
        }
        else {
          this.newGrid[i][j] = 0;
          this.newGrid[i-1][j-1] = type;
          
          this.smokeTimes[i-1][j-1] = this.smokeTimes[i][j];
          this.smokeTimes[i][j] = 0;
        }
      }
      else if (j+1 < this.gridHeight && this.newGrid[i-1][j+1] == 0) {
        int choice = (int)random(2);
        if (choice == 0) {
          this.newGrid[i][j] = 0;
          this.newGrid[i-1][j] = type;
          
          this.smokeTimes[i-1][j] = this.smokeTimes[i][j];
          this.smokeTimes[i][j] = 0;
        }
        else {
          this.newGrid[i][j] = 0;
          this.newGrid[i-1][j+1] = type;
          
          this.smokeTimes[i-1][j+1] = this.smokeTimes[i][j];
          this.smokeTimes[i][j] = 0;
        }
      }
      else {
        this.newGrid[i][j] = 0;
        this.newGrid[i-1][j] = type;
        
        this.smokeTimes[i-1][j] = this.smokeTimes[i][j];
        this.smokeTimes[i][j] = 0;
      }
    }
    else if (i-1 >= 0 && (j-1 >= 0 && this.newGrid[i-1][j-1] == 0) && (j+1 < this.gridHeight && this.newGrid[i-1][j+1] == 0)) {
      int choice = (int)random(2);
      if (choice == 0) {
        this.newGrid[i][j] = 0;
        this.newGrid[i-1][j-1] = type;
        
        this.smokeTimes[i-1][j-1] = this.smokeTimes[i][j];
        this.smokeTimes[i][j] = 0;
      }
      else {
        this.newGrid[i][j] = 0;
        this.newGrid[i-1][j+1] = type;
        
        this.smokeTimes[i-1][j+1] = this.smokeTimes[i][j];
        this.smokeTimes[i][j] = 0;
      }
    }
    else if (i-1 >= 0 && j-1 >= 0 && this.newGrid[i-1][j-1] == 0) {
      this.newGrid[i][j] = 0;
      this.newGrid[i-1][j-1] = type;
      
      this.smokeTimes[i-1][j-1] = this.smokeTimes[i][j];
      this.smokeTimes[i][j] = 0;
    }
    else if (i-1 >= 0 && j+1 < this.gridWidth && this.newGrid[i-1][j+1] == 0) {
      this.newGrid[i][j] = 0;
      this.newGrid[i-1][j+1] = type;
      
      this.smokeTimes[i-1][j+1] = this.smokeTimes[i][j];
      this.smokeTimes[i][j] = 0;
    }
    else if (j-1 >= 0 && this.newGrid[i][j-1] == 0) {
      if (j+1 < this.gridWidth && this.newGrid[i][j+1] == 0) {
        int choice = (int)random(2);
        if (choice == 0) {
          this.newGrid[i][j] = 0;
          this.newGrid[i][j-1] = type;
          
          this.smokeTimes[i][j-1] = this.smokeTimes[i][j];
          this.smokeTimes[i][j] = 0;
        }
        else {
          this.newGrid[i][j] = 0;
          this.newGrid[i][j+1] = type;
          
          this.smokeTimes[i][j+1] = this.smokeTimes[i][j];
          this.smokeTimes[i][j] = 0;
        }
      }
      else {
        this.newGrid[i][j] = 0;
        this.newGrid[i][j-1] = type;
        
        this.smokeTimes[i][j-1] = this.smokeTimes[i][j];
        this.smokeTimes[i][j] = 0;
      }
    }
    else if (j+1 < this.gridWidth && this.newGrid[i][j+1] == 0) {
      this.newGrid[i][j] = 0;
      this.newGrid[i][j+1] = type;
      
      this.smokeTimes[i][j+1] = this.smokeTimes[i][j];
      this.smokeTimes[i][j] = 0;
    }
  }
  
  void updateWater(int i, int j) {
     this.flow = 0;
     this.remaning_mass = this.waterGrid[i][j];
     if ( this.remaning_mass <= 0 ) return;
     
     if (i+1 < this.gridHeight && (this.newGrid[i+1][j] == 0 || this.newGrid[i+1][j] == 5 || this.newGrid[i+1][j] == 6 || this.newGrid[i+1][j] == 4)) {
       this.newWaterGrid[i+1][j] = this.waterGrid[i][j];
       this.newWaterGrid[i][j] = 0;
       
       this.newGrid[i][j] = 0;
       this.newGrid[i+1][j] = 7;
       
       return;
     }
     else if (i+1 < this.gridHeight && j-1 >= 0 && j+1 < this.gridWidth && (this.newGrid[i+1][j-1] == 0 || this.newGrid[i+1][j-1] == 5 || this.newGrid[i+1][j-1] == 6 || this.newGrid[i+1][j-1] == 4) && (this.newGrid[i+1][j+1] == 0 || this.newGrid[i+1][j+1] == 5 || this.newGrid[i+1][j+1] == 6 || this.newGrid[i+1][j+1] == 4)) {
       
       this.newWaterGrid[i+1][j-1] = this.waterGrid[i][j]/2;
       this.newWaterGrid[i+1][j+1] = this.waterGrid[i][j]/2;
       this.newWaterGrid[i][j] = 0;
       
       this.newGrid[i][j] = 0;
       this.newGrid[i+1][j-1] = 7;
       this.newGrid[i+1][j+1] = 7;
       
       return;
     }
     if ( (i+1 < this.gridHeight && (this.newGrid[i+1][j] == 7 || this.newGrid[i+1][j] == 0 || this.newGrid[i+1][j] == 5 || this.newGrid[i+1][j] == 6 || this.newGrid[i+1][j] == 4)) ){
       this.flow = this.get_stable_state_b(this.remaning_mass + this.waterGrid[i+1][j]) - this.waterGrid[i+1][j];
       
       if ( this.flow > this.MinFlow ){
         this.flow *= 0.5;
       }
       this.flow = constrain( this.flow, 0, min(this.MaxSpeed, this.remaning_mass) );
        
       this.newWaterGrid[i][j] -= this.flow;
       this.newWaterGrid[i+1][j] += this.flow;   
       this.remaning_mass -= this.flow;
     }
     
     if ( this.remaning_mass <= 0 ) return;
     
     if (j-1 >= 0 && (this.newGrid[i][j-1] == 7 || this.newGrid[i][j-1] == 0 || this.newGrid[i][j-1] == 5 || this.newGrid[i][j-1] == 6 || this.newGrid[i][j-1] == 4)){
       this.flow = (this.waterGrid[i][j] - this.waterGrid[i][j-1])/4;
       if ( this.flow > this.MinFlow ){ this.flow *= 0.5; }
       this.flow = constrain(this.flow, 0, this.remaning_mass);
         
       this.newWaterGrid[i][j] -= this.flow;
       this.newWaterGrid[i][j-1] += this.flow;   
       this.remaning_mass -= this.flow;
     }
      
     if ( this.remaning_mass <= 0 ) return;
     
     if (j+1 < this.gridWidth && (this.newGrid[i][j+1] == 7 || this.newGrid[i][j+1] == 0 || this.newGrid[i][j+1] == 5 || this.newGrid[i][j+1] == 6 || this.newGrid[i][j+1] == 4) ){
       this.flow = (this.waterGrid[i][j] - this.waterGrid[i][j+1])/4;
       if ( this.flow > this.MinFlow ){ this.flow *= 0.5; }
       this.flow = constrain(this.flow, 0, this.remaning_mass);
       
       this.newWaterGrid[i][j] -= this.flow;
       this.newWaterGrid[i][j+1] += this.flow;   
       this.remaning_mass -= this.flow;
     }
      
     if ( this.remaning_mass <= 0 ) return;
     
     if (i-1 >= 0 && (this.newGrid[i-1][j] == 7 || this.newGrid[i-1][j] == 0 || this.newGrid[i-1][j] == 5 || this.newGrid[i-1][j] == 6 || this.newGrid[i-1][j] == 4)){
       this.flow = this.remaning_mass - get_stable_state_b( this.remaning_mass + this.waterGrid[i-1][j] );
       if ( this.flow > this.MinFlow ){ this.flow *= 0.5; }
       this.flow = constrain( this.flow, 0, min(this.MaxSpeed, this.remaning_mass) );
        
       this.newWaterGrid[i][j] -= this.flow;
       this.newWaterGrid[i-1][j] += this.flow;   
       this.remaning_mass -= this.flow;
     }
     
     
  }
  
  void updateTNT(int i, int j, int r) {
    this.smokeTimes[i][j]--;
    if (this.smokeTimes[i][j] > 0) {
      if (i+1 < this.gridHeight && this.newGrid[i+1][j] == 0) {
        this.newGrid[i][j] = 0;
        this.newGrid[i+1][j] = 8;
        
        this.smokeTimes[i+1][j] = this.smokeTimes[i][j];
        this.smokeTimes[i][j] = 0;
      }
    } else {
      for (int x = i - r; x <= i + r; x++) {
          for (int y = j - r; y <= j + r; y++) {
              if (x >= 0 && x < this.gridWidth && y >= 0 && y < this.gridHeight) {
                  int distance = abs(x - i) + abs(y - j);
                  //int distance = Math.max(Math.abs(x - i), Math.abs(y - j));// Chebyshev distance (square radius)
                  if (distance <= r) {
                      this.newGrid[x][y] = 0;
                      this.newWaterGrid[x][y] = 0;
                      this.smokeTimes[x][y] = 0;
                  }
              }
          }
      }
    }
  }
  
  void update() {
    this.updateNewGrid();
    this.flow = 0;
    for (int j = 0; j < this.gridWidth; j++) {
      for (int i = 0; i < this.gridHeight; i++) {
        if (this.generation < 15) {
          int neighbours = 0;
          for (int k = i - 1; k <= i + 1; k++) {
            if (k < 0 || k >= this.gridHeight) continue;
            if (k == i) {
              for (int l = j - 1; l <= j + 1; l += 2) {
                if (l < 0 || l >= this.gridWidth) continue;
                if (grid[k][l] == 1) neighbours++;
              }
            } else {
              for (int l = j - 1; l <= j + 1; l ++) {
                if (l < 0 || l >= this.gridWidth) continue;
                if (this.grid[k][l] == 1) neighbours++;
              }
            }
          }
          if (this.grid[i][j] == 0) {
            if (containsElement(this.B, neighbours)) {
              this.newGrid[i][j] = 1;
            } else this.newGrid[i][j] = 0;
          } else if (this.grid[i][j] == 1) {
            if (containsElement(this.S, neighbours)) {
              newGrid[i][j] = 1;
            } else newGrid[i][j] = 0;
          }
        } else if (generation == 15) {
          this.generateElements();
          this.generation++;
        } else {
          if (this.grid[i][j] == 2) this.updateSand(i, j);
          else if (this.grid[i][j] == 3) this.updateWood(i, j);
          else if (this.grid[i][j] == 4) this.updateFire(i, j);
          else if (this.grid[i][j] == 5 || this.grid[i][j] == 6) this.updateSmoke(i, j, this.grid[i][j]);
          else if (this.grid[i][j] == 7) this.updateWater(i, j);
          else if (this.grid[i][j] == 8) this.updateTNT(i, j, 10);
        }
      }
    }
    this.updateGrid();
    if (this.generation > 16) {
      for (int k = 0; k < this.gridHeight; k++) {
        for (int l = 0; l < this.gridWidth; l++) {
           this.waterGrid[k][l] = this.newWaterGrid[k][l];
        }
      }
      for (int k = 0; k < this.gridHeight; k++) {
        for (int l = 0; l < this.gridWidth; l++) {
           if(this.grid[k][l] != 0 && this.newGrid[k][l] != 7 && this.newGrid[k][l] != 5 && this.newGrid[k][l] != 6) continue;
           if (this.waterGrid[k][l] > 0.0001){
             this.grid[k][l] = 7;
           } else if (this.grid[k][l] == 7) {
             this.grid[k][l] = 0;
           }
        }
      }
    }
    
    this.generation++;
    println("Generation: " + this.generation);
  }
  
  void generateElements() {
    for (int i = 0; i < this.gridHeight; i++) {
      for (int j = 0; j < this.gridWidth; j++) {
        if (this.grid[i][j] == 1) continue;
        float r = random(1);
        if (r < 0.15) {
            //grid[i][j] = 2;
        } else if (r < 0.3) {
            //grid[i][j] = 3;
        } else if (r < 0.5) {
            //this.newGrid[i][j] = 7;
            //this.waterGrid[i][j] = 1.;
        }
        else if (r > 0.8) {
            //grid[i][j] = 4;
        }
      }
    }
    
    for (int k = 0; k < this.gridHeight; k++) {
      for (int l = 0; l < this.gridWidth; l++) {
         this.newWaterGrid[k][l] = this.waterGrid[k][l];
      }
    }
  }
  
  void generateGrid() {
    float fillProbability = random(0.4, 0.5);
    for (int i = 0; i < this.gridHeight; i++) {
      int[] rowGrid = new int[this.gridWidth];
      int[] rowNewGrid = new int[this.gridWidth];
      int[] rowSmokeTimes = new int[this.gridWidth];
      float[] rowNewWaterGrid= new float[this.gridWidth];
      float[] rowWaterGrid = new float[this.gridWidth];
      float[] rowWaterPressure = new float[this.gridWidth];
      for (int j = 0; j < gridWidth; j++) {
          float r = random(1);
          //r = 1;
          if (r < fillProbability) {
              rowGrid[j] = 1;
              rowNewGrid[j] = 1;
          } else {
              rowGrid[j] = 0;
              rowNewGrid[j] = 0;
          }
          rowWaterGrid[j] = 0.;
          rowWaterPressure[j] = 0.;
          rowNewWaterGrid[j] = 0.;
          rowSmokeTimes[j] = 0;
      }
      this.grid[i] = rowGrid;
      this.newGrid[i] = rowNewGrid;
      this.waterGrid[i] = rowWaterGrid;
      this.waterPressure[i] = rowWaterPressure;
      this.newWaterGrid[i] = rowNewWaterGrid;
      this.smokeTimes[i] = rowSmokeTimes;
    }
  }
  
  void drawGrid() {
    for (int i = 0; i < this.gridHeight; i++) {
      for (int j = 0; j < this.gridWidth; j++) {
        if (this.grid[i][j] == 0) fill(0);
        else if (this.grid[i][j] == 1) fill(255);
        else if (this.grid[i][j] == 2) fill(194, 178, 128);
        else if (this.grid[i][j] == 3) fill(148,115,81);
        else if (this.grid[i][j] == 4) fill(255,90,0);
        else if (this.grid[i][j] == 5) fill(200);
        else if (this.grid[i][j] == 6) fill(100);
        else if (this.grid[i][j] == 8) fill(255,153,19);
        else if (this.grid[i][j] == 7) {
          float gradientFactor = (this.waterTreshold + 1 - this.waterGrid[i][j]) * 200;
          gradientFactor = constrain(gradientFactor, 0, 255); 
          
          int r = (int) lerp(10, 240, gradientFactor / 255.0);
          int g = (int) lerp(25, 240, gradientFactor / 255.0);
          int b = (int) lerp(112, 255, gradientFactor / 255.0);
          fill(r, g, b);
        } 
        
        rect(j * this.squareSize, i * this.squareSize, this.squareSize, this.squareSize);
        
        //if (this.grid[i][j] == 7) {
        //  fill(255);
        //  textAlign(CENTER, CENTER);
        //  float textX = j * squareSize + squareSize / 2;
        //  float textY = i * squareSize + squareSize / 2;
        //  text(this.waterGrid[i][j], textX, textY);
        //}
        //if (this.grid[i][j] == 8) {
        //  fill(255, 0, 0);
        //  textAlign(CENTER, CENTER);
        //  float textX = j * squareSize + squareSize / 2;
        //  float textY = i * squareSize + squareSize / 2;
        //  text("O  O\n", textX, textY);
        //}
      }
    }
  }

}

Grid myGrid;
boolean doLoop = true;
int block = 0;

void setup() {
  size(800, 800);
  background(100, 100, 100);
  myGrid = new Grid(10, 80, 80, "B678/S2345678", 150, 0.02);
  myGrid.generateGrid();
  myGrid.drawGrid();
  //myGrid.printGrid();
}

void draw() {
  if (doLoop) {
    background(100);
    myGrid.update();
    myGrid.drawGrid();
    //myGrid.printGrid();
    delay(100);
  
    
    int clickedRow = (int)(mouseY / myGrid.squareSize);
    int clickedCol = (int)(mouseX / myGrid.squareSize);
    
    if ( mousePressed && myGrid.generation > 16 ){
      if(clickedRow < myGrid.gridHeight && clickedRow >= 0) {
        if (clickedCol < myGrid.gridWidth && clickedCol >= 0) {
          myGrid.grid[clickedRow][clickedCol] = block;
          if (block == 7) {
            myGrid.waterGrid[clickedRow][clickedCol] = 1.;  
          }
          else if (block == 8) {
            myGrid.smokeTimes[clickedRow][clickedCol] = 25;  
          }
          else {
            myGrid.waterGrid[clickedRow][clickedCol] = 0;
            myGrid.smokeTimes[clickedRow][clickedCol] = 0;
          }
        }
      }
    }
  }
}

void keyPressed() {
  switch(key){
    case 's':
    case 'S': 
      block = 2;
      break;
    case 't':
    case 'T': 
      block = 3;
      break;
    case 'w':
    case 'W': 
      block = 7;
      break;
    case 'b':
    case 'B': 
      block = 1;
      break;
    case 'd':
    case 'D': 
      block = 0;
      break;
    case 'f':
    case 'F': 
      block = 4;
      break;
    case 'g':
    case 'G': 
      block = 8;
      break;
    default:
      block = 0;
      break;
  }
}

void mousePressed() {
  doLoop = true;
}
