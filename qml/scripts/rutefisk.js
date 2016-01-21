/*
This file is part of harbour-rutefisk.

    harbour-rutefisk is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    harbour-rutefisk is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with harbour-rutefisk.  If not, see <http://www.gnu.org/licenses/>.
*/

function add_district(listModel) {
  var places = {};
  for(var i=0; i < listModel.count; i++) {
    var name = listModel.get(i).Name;
    if(places.hasOwnProperty(name)) {
      listModel.setProperty(i, 'Name', name + ' (' + listModel.get(i).District + ')');
      if(places[name] == 1)
        for (var j=0; j < i; j++) {
          if(listModel.get(j).Name == name) {
            listModel.setProperty(j, 'Name', name + ' (' + listModel.get(j).District + ')');
          }
        }
      places[name] = 2;
    } else {
      places[listModel.get(i).Name] = 1;
    }
  }
}

Date.prototype.dst = function() {
  var julOffset = new Date(this.getFullYear(), 6, 1).getTimezoneOffset();
  console.log("jul offset " + julOffset);
  console.log("this offset " + this.getTimezoneOffset());
  return this.getTimezoneOffset() == julOffset;
}
