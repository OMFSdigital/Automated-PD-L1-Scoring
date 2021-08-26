/* Automated PD-L1 scoring of TPS, CPS, and ICS in whole slide images in a MATLAB/QuPath workflow
   Copyright (C) 2020-2021 Behrus Puladi
   https://orcid.org/0000-0001-5909-6105
   
   This program is free software; you can redistribute it and/or
   modify it under the terms of the GNU General Public License
   as published by the Free Software Foundation; either version 2
   of the License, or (at your option) any later version.
   
   This program is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
   GNU General Public License for more details.
   
   You should have received a copy of the GNU General Public License
   along with this program; if not, write to the Free Software
   Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA. */

def server = getCurrentServer()
def String filename = server.getMetadata().getName()

// Specify regex to extract case names from file names
def casename = (filename =~ /\d{2}-\w{1}\d{4}/).findAll()[0]
def cal = server.getPixelCalibration()
double pixelWidth = cal.getPixelWidthMicrons()
double pixelHeight = cal.getPixelHeightMicrons()

// Select all tumor objects
def tumor = getPathClass("TUM")
def tumorObjects = getObjects({p -> tumor.isAncestorOf(p.getPathClass())})

// Select all immune objects
def immune = getPathClass("LYM")
def immuneObjects = getObjects({p -> immune.isAncestorOf(p.getPathClass())})

// Defined threshold for DAB
double threshold = 0.35 

// Reset all existing intensity classifications
resetIntensityClassifications()
setIntensityClassifications(tumorObjects, "Smoothed: 25 µm: DAB: Membrane: Max", threshold)
setIntensityClassifications(immuneObjects, "Smoothed: 25 µm: DAB: Cell: Max", threshold)

// Apply the changes
fireHierarchyUpdate()

// Get all detected cells by class
def tumorCellsPositive = getCellObjects().findAll({it.getPathClass() == getPathClass("TUM: Positive")});
def tumorCellsNegative = getCellObjects().findAll({it.getPathClass() == getPathClass("TUM: Negative")});
def immuneCellsPositive = getCellObjects().findAll({it.getPathClass() == getPathClass("LYM: Positive")});
def immuneCellsNegative = getCellObjects().findAll({it.getPathClass() == getPathClass("LYM: Negative")});

// Calculate number of cells
def numberTumorPositive = tumorCellsPositive.size();
def numberTumorNegative = tumorCellsNegative.size();
def numberTumorAll = numberTumorPositive + numberTumorNegative;

def numberImmunePositive = immuneCellsPositive.size();
def numberImmuneNegative = immuneCellsNegative.size();
def numberImmuneAll = numberImmunePositive + numberImmuneNegative;

// Calculate area of cells
def immuneAreaPositive = 0;
for (immunCell in immuneCellsPositive){
    immuneAreaPositive = immuneAreaPositive + immunCell.getMeasurementList().getMeasurementValue("Cell: Area µm^2")
}

def immuneAreaNegative = 0;
for (immunCell in immuneCellsNegative){
    immuneAreaNegative = immuneAreaNegative + immunCell.getMeasurementList().getMeasurementValue("Cell: Area µm^2")
}

def tumorAreaPositive = 0;
for (tumorCell in tumorCellsPositive){
    tumorAreaPositive = tumorAreaPositive + tumorCell.getMeasurementList().getMeasurementValue("Cell: Area µm^2")
}

def tumorAreaNegative = 0;
for (tumorCell in tumorCellsNegative){
    tumorAreaNegative = tumorAreaNegative + tumorCell.getMeasurementList().getMeasurementValue("Cell: Area µm^2")
}

// Calculate areas 
def tumorAreaTotal = tumorAreaPositive + tumorAreaNegative;
def allAreaTotal = tumorAreaPositive + tumorAreaNegative + immuneAreaNegative + immuneAreaPositive;

// Calculate PD-L1 scores
def TPS = (Math.round((numberTumorPositive  / numberTumorAll)*1000) as double) / 10;
def CPS = (Math.round(((numberTumorPositive + numberImmunePositive) / numberTumorAll)*1000) as double) / 10;
def ICS = (Math.round((immuneAreaPositive / allAreaTotal)*1000) as double) / 10;

print(casename + "\t" + TPS +"\t" + CPS + "\t" + ICS  + '\n')


  
