bool compareArrays(List array1, List array2) {
  if (array1.length == array2.length) {
    return array1.every( (value) => array2.contains(value) );
  } else {
    return false;
  }
}