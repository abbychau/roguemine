const express = require('express');
const { encodeHighscore, decodeHighscore } = require('../encoding');
const HighscoreModel = require('../models/highscore');
const { validateHighscoreData, detectSuspiciousPatterns, validateHighscoreSubmission } = require('../middleware/validation');

const router = express.Router();

/**
 * Submit a new highscore
 * POST /api/highscores
 */
router.post('/', validateHighscoreSubmission, async (req, res) => {
  try {
    const { encodedData } = req.body;
    
    if (!encodedData) {
      return res.status(400).json({ error: 'Encoded data is required' });
    }
    
    // Decode the highscore data
    const decodedResult = decodeHighscore(encodedData);

    if (!decodedResult.success) {
      return res.status(400).json({ error: 'Invalid encoded data: ' + decodedResult.error });
    }
    
    const { playerName, score, timeTaken, tilesRevealed, chordsPerformed, timestamp } = decodedResult.data;

    // Comprehensive server-side validation
    const validation = validateHighscoreData(playerName, score, timeTaken, tilesRevealed, chordsPerformed);
    if (!validation.isValid) {
      console.error('Validation failed:', validation.errors);
      return res.status(400).json({
        error: 'Validation failed',
        details: validation.errors
      });
    }

    // Check for suspicious patterns
    const suspiciousFlags = detectSuspiciousPatterns(playerName, score, timeTaken, tilesRevealed, chordsPerformed);
    if (suspiciousFlags.length > 0) {
      console.warn('Suspicious score submission detected:', {
        playerName, score, timeTaken, tilesRevealed, chordsPerformed,
        flags: suspiciousFlags,
        ip: req.ip
      });

      // For now, just log suspicious activity. In production, you might want to:
      // - Require additional verification
      // - Flag for manual review
      // - Apply stricter rate limiting
    }
    
    // Get client IP
    const ipAddress = req.ip || req.socket.remoteAddress || 'unknown';
    
    // Save to database
    const saveResult = await HighscoreModel.saveHighscore(
      encodedData, playerName, score, timeTaken, 
      tilesRevealed, chordsPerformed, timestamp, ipAddress
    );
    
    // Get rank for this score
    const rank = await HighscoreModel.getRankForScore(score, timeTaken);
    
    // Check if it's a top score
    const isTopScore = await HighscoreModel.isTopScore(score, timeTaken);
    
    res.json({
      success: true,
      id: saveResult.id,
      rank: rank,
      isTopScore: isTopScore,
      message: isTopScore ? 'Congratulations! You made it to the leaderboard!' : 'Score saved successfully!'
    });
    
  } catch (error) {
    console.error('Error saving highscore:', error);
    
    if (error.message === 'Duplicate highscore data') {
      res.status(409).json({ error: 'This score has already been submitted' });
    } else {
      res.status(500).json({ error: 'Failed to save highscore' });
    }
  }
});

/**
 * Get top highscores
 * GET /api/highscores?limit=10
 */
router.get('/', async (req, res) => {
  try {
    const limit = Math.min(parseInt(req.query.limit) || 10, 100); // Max 100 entries
    
    const highscores = await HighscoreModel.getTopHighscores(limit);
    const totalCount = await HighscoreModel.getTotalCount();
    
    res.json({
      success: true,
      highscores: highscores,
      totalCount: totalCount,
      limit: limit
    });
    
  } catch (error) {
    console.error('Error fetching highscores:', error);
    res.status(500).json({ error: 'Failed to fetch highscores' });
  }
});

/**
 * Check if a score would qualify for top rankings
 * POST /api/highscores/check
 */
router.post('/check', async (req, res) => {
  try {
    const { score, timeTaken } = req.body;
    
    if (typeof score !== 'number' || typeof timeTaken !== 'number') {
      return res.status(400).json({ error: 'Score and time taken are required' });
    }
    
    const rank = await HighscoreModel.getRankForScore(score, timeTaken);
    const isTopScore = await HighscoreModel.isTopScore(score, timeTaken);
    
    res.json({
      success: true,
      rank: rank,
      isTopScore: isTopScore
    });
    
  } catch (error) {
    console.error('Error checking score:', error);
    res.status(500).json({ error: 'Failed to check score' });
  }
});

/**
 * Test encoding endpoint (development only)
 */
if (process.env.NODE_ENV === 'development') {
  router.post('/test-encode', (req, res) => {
    try {
      const { playerName, score, timeTaken, tilesRevealed, chordsPerformed } = req.body;
      
      const result = encodeHighscore(playerName, score, timeTaken, tilesRevealed, chordsPerformed);
      
      res.json(result);
      
    } catch (error) {
      res.status(500).json({ error: error.message });
    }
  });
  
  router.post('/test-decode', (req, res) => {
    try {
      const { encodedData } = req.body;
      
      const result = decodeHighscore(encodedData);
      
      res.json(result);
      
    } catch (error) {
      res.status(500).json({ error: error.message });
    }
  });
}

module.exports = router;
