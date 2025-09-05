/**
 * API Client for RogueMine Highscore Backend
 * Handles communication with the backend server
 */

class RogueMineAPIClient {
  constructor(baseURL = 'http://localhost:3000', secret = 'default-secret-key') {
    this.baseURL = baseURL.replace(/\/$/, ''); // Remove trailing slash
    this.encoder = new RogueMineEncoder(secret);
  }
  
  /**
   * Make HTTP request
   */
  async makeRequest(endpoint, options = {}) {
    const url = `${this.baseURL}${endpoint}`;
    
    const defaultOptions = {
      headers: {
        'Content-Type': 'application/json',
      },
    };
    
    const requestOptions = {
      ...defaultOptions,
      ...options,
      headers: {
        ...defaultOptions.headers,
        ...options.headers,
      },
    };
    
    try {
      const response = await fetch(url, requestOptions);
      const data = await response.json();
      
      if (!response.ok) {
        throw new Error(data.error || `HTTP ${response.status}`);
      }
      
      return data;
    } catch (error) {
      console.error('API request failed:', error);
      throw error;
    }
  }
  
  /**
   * Submit a highscore
   */
  async submitHighscore(playerName, score, timeTaken, tilesRevealed, chordsPerformed) {
    try {
      // Encode the data
      const encodingResult = this.encoder.encodeHighscore(
        playerName, score, timeTaken, tilesRevealed, chordsPerformed
      );
      
      if (!encodingResult.success) {
        throw new Error('Failed to encode data: ' + encodingResult.error);
      }
      
      // Submit to server
      const response = await this.makeRequest('/api/highscores', {
        method: 'POST',
        body: JSON.stringify({
          encodedData: encodingResult.encodedData
        })
      });
      
      return response;
      
    } catch (error) {
      console.error('Failed to submit highscore:', error);
      throw error;
    }
  }
  
  /**
   * Get top highscores
   */
  async getHighscores(limit = 10) {
    try {
      const response = await this.makeRequest(`/api/highscores?limit=${limit}`);
      return response;
    } catch (error) {
      console.error('Failed to get highscores:', error);
      throw error;
    }
  }
  
  /**
   * Check if a score would qualify for top rankings
   */
  async checkScore(score, timeTaken) {
    try {
      const response = await this.makeRequest('/api/highscores/check', {
        method: 'POST',
        body: JSON.stringify({
          score: score,
          timeTaken: timeTaken
        })
      });
      
      return response;
    } catch (error) {
      console.error('Failed to check score:', error);
      throw error;
    }
  }
  
  /**
   * Test server connection
   */
  async testConnection() {
    try {
      const response = await this.makeRequest('/health');
      return response;
    } catch (error) {
      console.error('Failed to connect to server:', error);
      throw error;
    }
  }
}

// Export for different environments
if (typeof module !== 'undefined' && module.exports) {
  // Node.js environment
  module.exports = RogueMineAPIClient;
} else if (typeof window !== 'undefined') {
  // Browser environment
  window.RogueMineAPIClient = RogueMineAPIClient;
}
