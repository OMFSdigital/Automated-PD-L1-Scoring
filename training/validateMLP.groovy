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
 
// Select all tumor objects
def tumor = getPathClass("TUM")
def tumorObjects = getObjects({p -> tumor.isAncestorOf(p.getPathClass())})

// Select all immune objects
def immune = getPathClass("LYM")
def immuneObjects = getObjects({p -> immune.isAncestorOf(p.getPathClass())})
  
// Select all other objects
def stromal = getPathClass("STR")
def stromalObjects = getObjects({p -> stromal.isAncestorOf(p.getPathClass())})
   
// Get all detected cells
def numberTumor = getCellObjects().findAll({it.getPathClass() == getPathClass("TUM")}).size()
def numberImmune = getCellObjects().findAll({it.getPathClass() == getPathClass("LYM")}).size()
def numberStromal = getCellObjects().findAll({it.getPathClass() == getPathClass("STR")}).size()
 
def numberAll = numberTumor + numberImmune + numberStromal
 
print(filename + "\t" + 
    Math.round(numberTumor/numberAll*100)/100 +"\t" + 
    Math.round(numberImmune/numberAll*100)/100 + "\t" + 
    Math.round(numberStromal/numberAll*100)/100 + "\n")
