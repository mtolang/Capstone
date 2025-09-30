## YouTube API Configuration Guide

### Getting Your YouTube Data API v3 Key

1. **Go to Google Cloud Console:**
   - Visit: https://console.cloud.google.com/

2. **Create a New Project or Select Existing:**
   - Click "Select a Project" → "New Project"
   - Name: "Capstone Therapy App"
   - Click "Create"

3. **Enable YouTube Data API v3:**
   - Go to "APIs & Services" → "Library"
   - Search for "YouTube Data API v3"
   - Click on it and press "Enable"

4. **Create API Credentials:**
   - Go to "APIs & Services" → "Credentials"
   - Click "Create Credentials" → "API Key"
   - Copy the generated API key

5. **Configure API Key (Optional but Recommended):**
   - Click on your API key to edit
   - Under "API restrictions", select "Restrict key"
   - Choose "YouTube Data API v3"
   - Save

### Adding API Key to Your App

1. **Replace the API Key in parent_materials.dart:**
   ```dart
   static const String _youtubeApiKey = 'YOUR_ACTUAL_API_KEY_HERE';
   ```

2. **For Production (Recommended):**
   - Store API key in environment variables
   - Use firebase_remote_config for secure key storage

### API Usage Quotas

- **Free Tier:** 10,000 units/day
- **Search Request:** 100 units per request
- **Video Details:** 1-4 units per request

### Search Categories

The app searches for videos with these keywords:
- "child developmental therapy"
- Combined with therapy categories:
  - Speech Therapy
  - Occupational Therapy
  - Physical Therapy
  - Behavioral Therapy
  - Play Therapy
  - Sensory Integration
  - Social Skills
  - Communication
  - Motor Skills

### API Response Structure

```json
{
  "items": [
    {
      "id": {"videoId": "video_id"},
      "snippet": {
        "title": "Video Title",
        "description": "Video Description",
        "thumbnails": {
          "medium": {"url": "thumbnail_url"}
        },
        "channelTitle": "Channel Name"
      }
    }
  ]
}
```

### Testing Without API Key

The app includes fallback sample data for testing:
- Sample therapy videos
- Placeholder thumbnails
- Test descriptions

Replace `YOUR_YOUTUBE_API_KEY` with your actual key to enable live video fetching.