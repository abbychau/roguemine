/**
 * Validation middleware for RogueMine backend
 * Implements additional security checks and score validation
 */

/**
 * Validate highscore data for realistic values
 */
function validateHighscoreData(playerName, score, timeTaken, tilesRevealed, chordsPerformed) {
  const errors = [];
  
  // Player name validation
  if (!playerName || typeof playerName !== 'string') {
    errors.push('Player name is required and must be a string');
  } else if (playerName.length < 1 || playerName.length > 50) {
    errors.push('Player name must be between 1 and 50 characters');
  } else if (!/^[a-zA-Z0-9\s\-_\.]+$/.test(playerName)) {
    errors.push('Player name contains invalid characters');
  }
  
  // Score validation
  if (!Number.isInteger(score) || score < 0) {
    errors.push('Score must be a non-negative integer');
  } else if (score > 10000000) {
    errors.push('Score is unrealistically high');
  }
  
  // Time validation
  if (typeof timeTaken !== 'number' || timeTaken <= 0) {
    errors.push('Time taken must be a positive number');
  } else if (timeTaken < 1) {
    errors.push('Time taken is unrealistically low (minimum 1 second)');
  } else if (timeTaken > 86400) {
    errors.push('Time taken is unrealistically high (maximum 24 hours)');
  }
  
  // Tiles revealed validation
  if (!Number.isInteger(tilesRevealed) || tilesRevealed < 1) {
    errors.push('Tiles revealed must be a positive integer');
  } else if (tilesRevealed > 250000) {
    errors.push('Tiles revealed exceeds maximum field size');
  }
  
  // Chords performed validation
  if (!Number.isInteger(chordsPerformed) || chordsPerformed < 0) {
    errors.push('Chords performed must be a non-negative integer');
  } else if (chordsPerformed > tilesRevealed) {
    errors.push('Chords performed cannot exceed tiles revealed');
  }
  
  // Cross-validation: Score vs performance metrics
  const minExpectedScore = tilesRevealed * 5; // Minimum 5 points per tile
  const maxExpectedScore = tilesRevealed * 100 + chordsPerformed * 1000; // Generous upper bound
  
  if (score < minExpectedScore) {
    errors.push('Score is too low for the number of tiles revealed');
  } else if (score > maxExpectedScore) {
    errors.push('Score is too high for the performance metrics');
  }
  
  // Time vs performance validation
  const minTimePerTile = 0.01; // 10ms per tile minimum
  const maxTimePerTile = 60; // 60 seconds per tile maximum
  
  const expectedMinTime = tilesRevealed * minTimePerTile;
  const expectedMaxTime = tilesRevealed * maxTimePerTile;
  
  if (timeTaken < expectedMinTime) {
    errors.push('Time taken is too fast for the number of tiles revealed');
  } else if (timeTaken > expectedMaxTime) {
    errors.push('Time taken is too slow for the number of tiles revealed');
  }
  
  return {
    isValid: errors.length === 0,
    errors: errors
  };
}

/**
 * Rate limiting by IP address
 */
const submissionCounts = new Map();
const SUBMISSION_WINDOW = 15 * 60 * 1000; // 15 minutes
const MAX_SUBMISSIONS_PER_WINDOW = 10;

function checkSubmissionRate(ipAddress) {
  const now = Date.now();
  const key = ipAddress;
  
  if (!submissionCounts.has(key)) {
    submissionCounts.set(key, []);
  }
  
  const submissions = submissionCounts.get(key);
  
  // Remove old submissions outside the window
  const validSubmissions = submissions.filter(timestamp => now - timestamp < SUBMISSION_WINDOW);
  submissionCounts.set(key, validSubmissions);
  
  // Check if limit exceeded
  if (validSubmissions.length >= MAX_SUBMISSIONS_PER_WINDOW) {
    return {
      allowed: false,
      message: `Too many submissions. Maximum ${MAX_SUBMISSIONS_PER_WINDOW} submissions per ${SUBMISSION_WINDOW / 60000} minutes.`,
      resetTime: Math.min(...validSubmissions) + SUBMISSION_WINDOW
    };
  }
  
  // Add current submission
  validSubmissions.push(now);
  submissionCounts.set(key, validSubmissions);
  
  return {
    allowed: true,
    remaining: MAX_SUBMISSIONS_PER_WINDOW - validSubmissions.length
  };
}

/**
 * Detect suspicious patterns
 */
function detectSuspiciousPatterns(playerName, score, timeTaken, tilesRevealed, chordsPerformed) {
  const suspiciousFlags = [];
  
  // Perfect scores (might be legitimate but worth flagging)
  if (score % 1000 === 0 && score > 10000) {
    suspiciousFlags.push('Perfect round score');
  }
  
  // Suspiciously round times
  if (timeTaken % 60 === 0 && timeTaken > 120) {
    suspiciousFlags.push('Suspiciously round time');
  }
  
  // Impossible efficiency
  const tilesPerSecond = tilesRevealed / timeTaken;
  if (tilesPerSecond > 50) {
    suspiciousFlags.push('Impossibly fast tile revealing');
  }
  
  // Too many chords relative to tiles
  const chordRatio = chordsPerformed / tilesRevealed;
  if (chordRatio > 0.5) {
    suspiciousFlags.push('Unusually high chord ratio');
  }
  
  // Common bot names
  const botPatterns = [
    /^bot\d+$/i,
    /^test\d*$/i,
    /^admin\d*$/i,
    /^player\d+$/i,
    /^user\d+$/i
  ];
  
  for (const pattern of botPatterns) {
    if (pattern.test(playerName)) {
      suspiciousFlags.push('Suspicious player name pattern');
      break;
    }
  }
  
  return suspiciousFlags;
}

/**
 * Middleware to validate highscore submissions
 */
function validateHighscoreSubmission(req, res, next) {
  const ipAddress = req.ip || req.connection.remoteAddress || 'unknown';
  
  // Check submission rate
  const rateCheck = checkSubmissionRate(ipAddress);
  if (!rateCheck.allowed) {
    return res.status(429).json({
      error: rateCheck.message,
      resetTime: rateCheck.resetTime
    });
  }
  
  // Add rate limit info to request
  req.rateLimitInfo = rateCheck;
  
  next();
}

/**
 * Clean up old rate limit data
 */
function cleanupRateLimitData() {
  const now = Date.now();
  for (const [key, submissions] of submissionCounts.entries()) {
    const validSubmissions = submissions.filter(timestamp => now - timestamp < SUBMISSION_WINDOW);
    if (validSubmissions.length === 0) {
      submissionCounts.delete(key);
    } else {
      submissionCounts.set(key, validSubmissions);
    }
  }
}

// Clean up every 5 minutes
setInterval(cleanupRateLimitData, 5 * 60 * 1000);

module.exports = {
  validateHighscoreData,
  checkSubmissionRate,
  detectSuspiciousPatterns,
  validateHighscoreSubmission
};
