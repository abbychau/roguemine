const { encodeHighscore, decodeHighscore } = require('./src/encoding');

console.log('=== Testing Encoding/Decoding ===');
console.log('Current timestamp:', Date.now());

// Test encoding a new score
console.log('\n1. Testing fresh encoding...');
const encodeResult = encodeHighscore('TestPlayer', 2923, 120.5, 150, 5);
console.log('Encode result:', encodeResult);

if (encodeResult.success) {
  console.log('\n2. Testing immediate decoding...');
  const decodeResult = decodeHighscore(encodeResult.encodedData);
  console.log('Decode result:', decodeResult);
}

// Test the latest problematic encoded data from Godot
console.log('\n3. Testing latest Godot encoded data...');
const latestGodotData = "URNbHXx9eHkBGlJNSbe6ohkBCQtxeG1qW1FCQ0e8ub8IXxoFZCw2ORtLXFUMp7alGB0aTGR3YGlSUFxVCqe2oQQDDBNkOSd5WFhHQkm1tKASAQ8HcXop";

console.log('Attempting to decode latest Godot data:', latestGodotData.substring(0, 50) + '...');
const latestResult = decodeHighscore(latestGodotData);
console.log('Latest decode result:', latestResult);

// Also test the old data
console.log('\n4. Testing old Godot encoded data...');
const oldGodotData = "tPS+xtHC1SJkfTcmFh8DCP3m5N3by8g1Mj4iLBAaBxTtuP/eyaKVYX5rZz4PCEMa9eLpyMmB2zo1NycvDwhFGvXk89LH0I1zJTQkLhsaAUU=";

console.log('Attempting to decode old Godot data:', oldGodotData.substring(0, 50) + '...');
const oldResult = decodeHighscore(oldGodotData);
console.log('Old decode result:', oldResult);
