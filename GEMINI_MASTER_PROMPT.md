# Master Prompt for Gemini AI Integration - Farm Assistant App

## 🌱 App Overview
**Farm Assistant** is an intelligent agricultural companion Flutter application designed to help farmers diagnose plant diseases, access agricultural news, get personalized care recommendations, and communicate with AI experts.

**Theme**: Modern agricultural technology with a green color scheme (Primary: #2E7D32, Light: #E8F5E9)
**Target Audience**: Indian farmers using mobile devices
**Key Language Support**: English, Hindi, Marathi, Kannada, Telugu, Tamil, Bengali, Punjabi

---

## 🏗️ Architecture & Core Services

### 1. **Disease Detection Pipeline**
```
User Image Input → Qubrid AI API (Online Mode)
                  OR TFLite Model (Offline Mode)
                  ↓
        JSON Response (is_plant, plant_name, disease_name, confidence)
                  ↓
        Result Screen Display
                  ↓
        Show Local Remedies (remedies.json) OR Request Gemini Analysis
```

**Services**:
- **QubridService**: Multimodal AI analysis using Qwen3-VL-8B model via Qubrid API
- **TFLiteService**: Offline TensorFlow Lite inference
- **Supported Plant Classes**: 39 disease conditions across Apple, Tomato, Potato, Corn, Grape, Orange, Peach, Pepper, Blueberry, Cherry, Raspberry, Soybean, Squash, Strawberry

### 2. **Information Systems**
- **NewsScreen**: Global & location-based agricultural news (GNews API)
- **ChatScreen**: Real-time AI conversation (Gemini 2.5 Flash)
- **ProfileScreen**: User settings & preferences
- **ReminderScreen**: Crop care scheduling
- **CareGuidesScreen**: Comprehensive plant care information

### 3. **Data Sources**
- **Qubrid API**: Plant disease detection
- **Google Gemini API**: Treatment recommendations & general queries
- **GNews API**: Agricultural news & updates
- **Geolocator & Geocoding**: Location-based services
- **SharedPreferences**: Local caching of news & user preferences
- **assets/remedies.json**: 39 plant disease remedies (local database)
- **assets/labels.txt**: Disease label taxonomy
- **TFLite Model**: Offline classification fallback

---

## 🎯 Main Screens & User Flow

### **Home Screen**
- Time-based greeting (Good Morning/Afternoon/Evening)
- Quick scan card → Direct to scan screen
- Agricultural news preview
- Plant tools: Plant Identifier, Diagnose, Reminder, Care Guides, Agri News, WhatsApp link

### **Scan Screen** 
- Camera feed with customizable frame overlay
- Online/Offline mode toggle
- Gallery picker, live capture, tips
- Real-time image analysis with loading states

### **Result Screen**
- Disease diagnosis with confidence percentage (0-100%)
- Three result types:
  1. **Healthy Plant** ✓ (Green theme)
  2. **Diseased Plant** ⚠️ (Orange theme) - Show remedies
  3. **Not a Plant** ✗ (Red theme) - Redirect to plant scan
- Action buttons:
  - Scan Again
  - Show Quick Remedies (local from JSON)
  - Ask AI for More Details (Gemini)
  - Send to WhatsApp

### **Chat Screen**
- Real-time AI conversation with Gemini
- Chat history management
- Message persistence
- Typing indicators
- Error handling & retry logic

### **News Screen**
- Two tabs: Global News & Local News
- Location-aware news filtering (Maharashtra-based)
- Article cards with images, date, description
- External link handling to full articles

### **Profile & Settings**
- User preferences
- Language selection
- Notification settings
- Account management

### **Navigation**
- Bottom navigation bar with 5 tabs
- Floating action button for direct scan access
- Deep linking for WhatsApp integration

---

## 💬 Gemini AI Integration Points

### **1. Treatment & Remedies Enhancement**
**When User Clicks**: "Ask AI for More Details"

**Current Implementation**: 
```dart
GeminiService.getRemedyForDisease(String diseaseName, double confidence)
```

**Prompt Context**:
```
You are an expert agricultural scientist and plant pathologist. 
A plant disease detection system has identified the following:
- Disease/Condition: [diseaseName]
- Confidence: [confidence]%

Provide: 
1. Disease Overview (2-3 sentences)
2. Symptoms to Look For (bullet points)
3. Causes (fungal/bacterial/environmental)
4. Treatment & Remedies (organic & chemical)
5. Prevention Tips
6. When to Seek Expert Help

Keep response practical & actionable. Use simple language for farmers.
```

**Response Format**: Markdown with bold headings, bullet points
**Output Handling**: Custom markdown parser with styled TextSpans

### **2. Free-Form Chat Assistant** 
**When User Opens**: Chat Screen

**Personality**: 
- Knowledgeable agricultural expert
- Farmer-friendly language
- Practical, solution-focused advice
- Contextual to Indian agriculture

**Capabilities**:
- Crop-specific Q&A
- Soil & fertilizer guidance
- Weather-related crop management
- Government schemes & subsidies
- Equipment & tools recommendations
- Market prices & demand trends
- Pest & disease prevention
- Irrigation techniques
- Seasonal planting guide
- Disease diagnosis follow-ups

**Current API Flow**:
```
User Message 
    ↓
ChatScreen → Gemini API (gemini-2.5-flash)
    ↓
Response displayed with proper formatting
    ↓
Stored in local history (optional)
```

### **3. App-Context Enrichment** (Future Enhancement)
When analyzing a scanned disease, you could:
- Cross-reference with recent news about that disease
- Suggest government subsidies for treatment
- Provide market updates for affected crops
- Link to care guides automatically

---

## 🎨 Design Language & Styling

### Color Palette
```dart
primaryGreen: #2E7D32     // Action buttons, icons
lightGreen: #E8F5E9       // Card backgrounds, highlights
accentGreen: #4CAF50      // Secondary actions
backgroundGreen: #F1F8E9  // App background
textDark: #1B5E20         // Primary text
textGrey: #757575         // Secondary text
```

### Component Patterns
- **Cards**: White background, 16dp border radius, subtle shadow
- **Buttons**: Rounded corners, adaptive colors based on context
- **Icons**: Material Design with color coding
- **Typography**: Bold headings for sections, regular body text, grey subtitles
- **Spacing**: Consistent 12/16/20/24dp margins

### User Feedback
- Loading states with spinners
- Error messages in SnackBars (red background)
- Success confirmations
- Confidence badges for disease detection
- Status messages during API calls

---

## 📊 Data Models

### Disease Analysis Result
```
{
  isPlant: Boolean,
  plantName: String?,
  label: String (e.g., "Tomato - Early Blight"),
  confidence: Double (0.0-1.0),
  description: String,
  imagePath: String,
  usedOfflineModel?: Boolean
}
```

### Chat Message
```
{
  text: String,
  isUser: Boolean,
  timestamp: DateTime
}
```

### Remedy Record
```json
{
  "plant_disease_remedies": {
    "Apple___Apple_scab": "Apply sulfur...",
    "Tomato___Early_blight": "Remove lower leaves...",
    ...
  }
}
```

---

## 🔌 API Integration Guidelines

### Gemini API (Current Implementation)
- **Model**: gemini-2.5-flash
- **Endpoint**: `https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent`
- **Temperature**: 0.7 (balanced creativity)
- **Max Tokens**: 1024
- **Timeout**: Standard HTTP timeout

### Response Handling
- Parse markdown-formatted responses
- Extract bold text for emphasis
- Convert bullet points to styled list items
- Display headings with size hierarchy
- Graceful fallback for parsing errors

### Error Management
- Network error messages
- API rate limiting (show user-friendly message)
- Retry mechanisms with exponential backoff
- Cached responses for offline access

---

## 🌍 Localization Support

**Available Languages**:
- English (en) - Default
- Hindi (hi) - 40% of target users
- Marathi (mr) - Regional support
- Kannada (kn), Telugu (te), Tamil (ta) - South India
- Bengali (bn), Punjabi (pa) - Extended coverage

**Gemini Response Handling**: Currently in English; consider locale-specific prompts in future

---

## 🔐 Security & Best Practices

### API Keys (Should be moved to secure config)
```
- Qubrid API Key: k_23a8149a1e86...
- Gemini API Key: AIzaSyC3CCyBg66M5AU4Jvcl24RgQ1yI9155l7Y
- GNews API Key: bccb2a5566a64f2d...
```

### Data Privacy
- Local caching for news articles
- No sensitive user data in API calls
- Device-based image processing before upload
- SharedPreferences for local preferences only

### Performance
- Image compression before transmission
- Lazy loading of news articles
- Pagination support (max=10 articles)
- Offline mode availability

---

## 📈 Enhanced Gemini Prompting Examples

### Example 1: Disease with Low Confidence
```
Disease: Tomato - Possible Early Blight
Confidence: 45%

You are a plant pathologist. The confidence in this disease diagnosis is below 60%. 
Provide:
1. What additional symptoms to look for
2. Other diseases this might be confused with
3. High-confidence identification tips
4. Recommendation: Should the farmer get expert verification?
```

### Example 2: Crop-Specific Advisory
```
User asks: "My potato crop leaves are yellowing"
Context: Maharashtra region, likely monsoon season

Provide targeted advice for:
1. Most common diseases causing yellowing in potatoes
2. Seasonal factors in Maharashtra
3. Treatment timeline
4. Prevention for next season
5. Link to local agricultural extension services
```

### Example 3: News-to-Action Integration
```
Recent News: "New subsidy scheme for organic farming 2024"
User Disease: "Tomato - Early Blight (detected today)"

Connect:
1. How organic treatments apply to this disease
2. Subsidy eligibility for organic certification
3. Transition timeline
4. Resources for organic pest management
```

---

## 🚀 Future Enhancement Opportunities

1. **Multi-turn Diagnosis**: 
   - Gemini asks clarifying questions about symptoms
   - Provides more accurate recommendations with additional context

2. **Real-time Updates**:
   - Push notifications for disease outbreaks in user's region
   - Seasonal alerts & planting recommendations

3. **Voice Interaction**:
   - Speech-to-text for chat
   - Audio responses from Gemini

4. **Image Analysis Enhancement**:
   - Multiple image angles analysis
   - Severity stage detection (mild/moderate/severe)
   - Progression tracking over time

5. **Community Features**:
   - Farmer-to-farmer disease sharing
   - Success story documentation
   - AI-powered farming groups

6. **Marketplace Integration**:
   - Direct product recommendations for treatments
   - Local vendor connections
   - Pricing comparison

---

## 📋 Prompt Template for Custom Gemini Requests

When integrating new Gemini features, use this template:

```
You are a specialized agricultural AI assistant for Indian farmers using the "Farm Assistant" mobile app.

Context:
- User Location: [region/state]
- Crop Type: [detected from scan or user input]
- Current Season: [monsoon/summer/winter]
- Previous Interactions: [relevant history]

User Query: [actual question]

Guidelines:
1. Use simple, farmer-friendly language
2. Provide practical, immediately actionable advice
3. Consider regional climate & agriculture practices
4. Reference government schemes when relevant
5. Include prevention tips for future seasons
6. Suggest expert consultation if needed
7. Format response with clear sections & bullet points
8. Keep response concise (under 1000 words for chat, under 400 for quick summaries)

Response Format: Markdown with **bold** for emphasis, bullet points for lists, numbers for steps.
```

---

## ✅ Testing Guidelines for Gemini Integration

1. **Disease Detection Accuracy**:
   - Test with images of each supported plant disease
   - Verify confidence scores are realistic (0-1.0)
   - Test with non-plant images (error handling)

2. **Remedy Retrieval**:
   - Compare local JSON remedies vs Gemini responses
   - Verify completeness & actionability
   - Check for regional applicability

3. **Chat Responsiveness**:
   - Test with 10+ farming-related queries
   - Verify multi-turn conversation context
   - Check error recovery

4. **Performance**:
   - API response time < 5 seconds for remedies
   - Chat messages appear within 2 seconds
   - Image analysis completes within 60 seconds

5. **Localization**:
   - Verify Gemini can handle regional context
   - Test language preferences (future enhancement)

---

## 📞 Support & Debugging

### Common Issues & Fixes
- **API Rate Limit**: Implement exponential backoff
- **Timeout**: Increase duration for slower networks
- **Parse Errors**: Add more fallback parsing logic
- **Offline Mode**: Cache recent responses
- **Locale Mismatch**: Store user language preference

### Monitoring
- Log API call timestamps & response times
- Track error rates by endpoint
- Monitor Gemini API quota usage
- Collect user feedback via ratings

---

## 🎓 Knowledge Base for Gemini

**Plant Disease Taxonomy** (39 conditions):
- **Apple** (3): Scab, Black Rot, Cedar Apple Rust, Healthy
- **Citrus** (1): Orange Haunglongbing
- **Corn** (4): Cercospora Leaf Spot, Common Rust, Northern Leaf Blight, Healthy
- **Grape** (4): Black Rot, Esca, Leaf Blight, Healthy
- **Tomato** (8): Bacterial Spot, Early Blight, Late Blight, Leaf Mold, Septoria Leaf Spot, Spider Mites, Target Spot, Yellow Curl Virus, Mosaic Virus, Healthy
- **Potato** (3): Early Blight, Late Blight, Healthy
- **Peach, Pepper, Blueberry, Cherry, Raspberry, Soybean, Squash, Strawberry**: 1-3 conditions each

**Treatment Database**: Comprehensive remedies in `assets/remedies.json`

---

*This master prompt ensures all Gemini interactions align with the Farm Assistant app's mission: empowering Indian farmers with AI-driven agricultural intelligence.*
