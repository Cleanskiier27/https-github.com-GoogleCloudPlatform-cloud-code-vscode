# Galaxy Navigation System - Integration Guide
## Complete Setup Instructions for NetworkBuster

---

## 🚀 Quick Start (5 minutes)

### Prerequisites
- Node.js 18+ installed
- npm 9+ installed
- React project (networkbuster.net)
- Azure Storage account (optional, for real-time data)

### Installation

**1. Run deployment script:**
```powershell
# On Windows PowerShell
.\deploy-galaxy-navigation.ps1 -Environment production

# Or with real-time Azure sync
.\deploy-galaxy-navigation.ps1 -Environment production -EnableRealTimeSync
```

**2. Install dependencies:**
```bash
npm install three @react-three/fiber @react-three/drei axios
```

**3. Start the application:**
```bash
npm start
```

**4. Access the galaxy map:**
```
http://localhost:3000/galaxy
```

---

## 📁 File Structure

```
networkbuster.net/
├── challengerepo/
│   └── real-time-overlay/
│       └── src/
│           └── components/
│               └── GalaxyMap.jsx (1,200+ lines)
├── src/
│   ├── lib/
│   │   └── aerospace-calculations.js (physics engine)
│   ├── integration/
│   │   └── galaxy-integration.js (NetworkBuster integration)
│   └── config/
│       └── azure-galaxy.json (configuration)
├── data/
│   └── galaxy-database/
│       └── stars.json (250 star systems)
├── AEROSPACE_GALAXY_NAVIGATION.md (complete documentation)
├── GALAXY_DEPLOYMENT_SUMMARY.md (deployment status)
└── deploy-galaxy-navigation.ps1 (automated setup)
```

---

## 🔧 Configuration

### Environment Variables (.env.galaxy)

```env
# Deployment Environment
REACT_APP_ENVIRONMENT=production
REACT_APP_API_BASE_URL=https://networkbuster.blob.core.windows.net

# Azure Storage
REACT_APP_STORAGE_ACCOUNT=networkbusterdata
REACT_APP_STORAGE_CONTAINER=galaxy-data

# Galaxy Settings
REACT_APP_INITIAL_ZOOM=50
REACT_APP_INITIAL_POSITION_X=0
REACT_APP_INITIAL_POSITION_Y=50
REACT_APP_INITIAL_POSITION_Z=100

# Real-time Updates
REACT_APP_ENABLE_REALTIME=true
REACT_APP_SYNC_INTERVAL=60000

# Physics Engine
REACT_APP_RELATIVITY_ENABLED=true
REACT_APP_WARP_DRIVE_ENABLED=false
REACT_APP_TIME_DILATION_VISIBLE=true

# Performance
REACT_APP_STAR_LOD=high
REACT_APP_PARTICLE_COUNT=50000
REACT_APP_UPDATE_FREQUENCY=60

# Analytics
REACT_APP_TRACK_ROUTES=true
REACT_APP_TRACK_DESTINATIONS=true
```

---

## 🌍 Integration with Existing Components

### 1. Real-Time Overlay Integration

Add to your real-time overlay component:

```jsx
// challengerepo/real-time-overlay/src/App.jsx

import GalaxyMap from './components/GalaxyMap';
import CameraFeed from './components/CameraFeed';

export const App = () => {
  const [showGalaxy, setShowGalaxy] = useState(false);

  return (
    <div className="overlay-container">
      <CameraFeed />
      
      {showGalaxy && (
        <GalaxyMap />
      )}
      
      <button onClick={() => setShowGalaxy(!showGalaxy)}>
        Toggle Galaxy Map
      </button>
    </div>
  );
};
```

### 2. Immersive Reader Integration

Enable reading star descriptions with text-to-speech:

```jsx
// Integration with immersive reader

import { ImmersiveReader } from './components/ImmersiveReader';

const StarDescription = ({ star }) => {
  const content = `
    ${star.name}
    
    Classification: ${star.type}
    Distance: ${star.distance} light-years
    Temperature: ${star.temperature}K
    Mass: ${star.mass} solar masses
    
    Planets: ${star.planets.join(', ')}
    Habitability: ${star.habitable ? 'Potentially Habitable' : 'Not Habitable'}
  `;

  return (
    <ImmersiveReader 
      content={content}
      language="en"
    />
  );
};
```

### 3. Analytics Integration

Track user destinations and routes:

```jsx
// Track galaxy map interactions

const trackGalaxyEvent = (eventType, eventData) => {
  const event = {
    type: eventType,
    timestamp: new Date().toISOString(),
    data: eventData,
    userId: getCurrentUserId(),
    source: 'galaxy-map'
  };

  // Send to Azure Log Analytics
  fetch('/api/analytics/event', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(event)
  });
};

// Usage
trackGalaxyEvent('destination_selected', {
  star: 'Proxima Centauri',
  route_distance: 4.24,
  vehicle_speed: 0.5
});
```

### 4. Azure Storage Integration

Store and retrieve star data from Azure:

```javascript
// src/lib/azure-galaxy-service.js

import axios from 'axios';

class AzureGalaxyService {
  constructor(storageAccount, container) {
    this.storageUrl = `https://${storageAccount}.blob.core.windows.net/${container}`;
  }

  async getStarDatabase() {
    try {
      const response = await axios.get(`${this.storageUrl}/stars.json`);
      return response.data;
    } catch (error) {
      console.error('Failed to fetch star database:', error);
      return null;
    }
  }

  async getRouteData(routeId) {
    const response = await axios.get(`${this.storageUrl}/routes/${routeId}.json`);
    return response.data;
  }

  async saveMissionData(missionId, data) {
    // Save to Azure using SAS token
    const sasToken = process.env.REACT_APP_STORAGE_SAS;
    const url = `${this.storageUrl}/missions/${missionId}.json?${sasToken}`;
    
    await axios.put(url, data, {
      headers: { 'x-ms-blob-type': 'BlockBlob' }
    });
  }

  async syncRealTimePositions() {
    // Called every 60 seconds for real-time star position updates
    setInterval(async () => {
      const positions = await this.getStarDatabase();
      return positions;
    }, 60000);
  }
}

export default AzureGalaxyService;
```

### 5. Database Integration

Store user routes and preferences:

```sql
-- SQL example for storing favorite routes

CREATE TABLE GalaxyRoutes (
  RouteId INT PRIMARY KEY,
  UserId VARCHAR(255) NOT NULL,
  OriginStar VARCHAR(255),
  DestinationStar VARCHAR(255),
  VehicleSpeed FLOAT,
  TravelTime VARCHAR(100),
  FuelRequired FLOAT,
  DateCreated DATETIME,
  IsPublic BIT
);

-- Query: Get popular routes
SELECT DestinationStar, COUNT(*) as PopularityScore
FROM GalaxyRoutes
WHERE DateCreated > DATEADD(MONTH, -1, GETDATE())
GROUP BY DestinationStar
ORDER BY PopularityScore DESC;
```

---

## 🎮 Usage Examples

### Example 1: Plan a Journey

```jsx
// User selects departure and destination

const [route, setRoute] = useState(null);

const planRoute = (origin, destination, speed) => {
  const distance = calculateDistance(origin, destination);
  const travelTime = calculateTravelTime(distance, speed);
  const relativity = calculateRelativity(speed);
  
  setRoute({
    origin: origin.name,
    destination: destination.name,
    distance: distance,
    travelTime: travelTime.formatted,
    relativistic: {
      timeDilation: relativity.timeDilation,
      massIncrease: relativity.massIncrease
    }
  });
};

// Result:
// Earth → Proxima Centauri
// Distance: 4.24 light-years
// Travel Time: 8.48 years (50% light speed)
// Time Dilation: 1.155x (saves 1.14 years for travelers!)
```

### Example 2: Calculate Fuel Requirements

```jsx
// Spacecraft acceleration calculation

const calculateFuelNeeds = (spacecraft) => {
  const deltaV = 150000; // km/s needed to reach 50% light speed
  const isp = 300000; // Specific impulse of ion drive
  
  const fuel = calculateFuelRequirements(deltaV, isp);
  
  return {
    massRatio: fuel.massRatio,
    wetMass: spacecraft.dryMass * fuel.massRatio,
    fuelMass: spacecraft.dryMass * (fuel.massRatio - 1)
  };
};

// Result: Requires 1000x dry mass in fuel (unrealistic!)
// Suggests: Need antimatter or exotic physics
```

### Example 3: Find Habitable Destinations

```jsx
// Filter for potentially habitable systems

const findHabitableDestinations = (maxDistance = 50) => {
  return GALAXY_DATABASE.filter(star => 
    star.habitable === true &&
    star.distance <= maxDistance &&
    star.planets > 0
  ).sort((a, b) => a.distance - b.distance);
};

// Results:
// 1. Proxima Centauri (4.24 ly) - High habitability
// 2. Alpha Centauri A (4.37 ly) - High habitability
// 3. Tau Ceti (11.9 ly) - High habitability
// 4. Epsilon Eridani (10.5 ly) - Moderate habitability
```

---

## 📊 Monitoring & Analytics

### KQL Queries for Galaxy Map Usage

```kusto
// Track most visited star systems
ContainerAppConsoleLogs
| where TimeGenerated > ago(24h)
| where Data contains "galaxy_destination"
| summarize VisitCount = count() by tostring(parsejson(Data).destination_star)
| sort by VisitCount desc
| limit 10

// Track average travel times calculated
ContainerAppConsoleLogs
| where TimeGenerated > ago(24h)
| where Data contains "travel_calculation"
| extend TravelTime = todouble(parsejson(Data).travel_years)
| summarize AvgTravelTime = avg(TravelTime), MaxTravelTime = max(TravelTime)

// Monitor galaxy map performance
ContainerAppConsoleLogs
| where TimeGenerated > ago(1h)
| where Data contains "render_fps"
| extend FPS = toint(parsejson(Data).fps)
| summarize AvgFPS = avg(FPS), MinFPS = min(FPS), MaxFPS = max(FPS)
```

---

## 🔐 Security Configuration

### Azure Storage Access

Store credentials securely in Azure Key Vault:

```powershell
# Create Key Vault secret
az keyvault secret set \
  --vault-name networkbuster-kv \
  --name GalaxyStorageSAS \
  --value "sv=2021-06-08&ss=b&srt=sco&sp=rwdlac&..."

# Retrieve in application
const sasToken = process.env.GALAXY_STORAGE_SAS;
```

### CORS Configuration

Enable cross-origin requests for Azure Blob:

```powershell
# Set CORS rules for galaxy-data container
az storage cors add \
  --account-name networkbusterdata \
  --methods GET POST OPTIONS \
  --origins "https://networkbuster.net" \
  --allowed-headers "*" \
  --expose-headers "*" \
  --max-age 3600
```

---

## 🚀 Deployment Checklist

- [ ] All dependencies installed
- [ ] Environment variables configured
- [ ] Star database uploaded to Azure
- [ ] Real-time sync enabled (if needed)
- [ ] Analytics pipeline connected
- [ ] Component integrated with overlay
- [ ] Immersive Reader enabled
- [ ] Performance tested (60+ FPS)
- [ ] Security credentials stored in Key Vault
- [ ] CORS configured for Azure
- [ ] Git commit created
- [ ] Documentation updated
- [ ] Tested on production environment

---

## 🐛 Troubleshooting

### Issue: Galaxy Map Not Rendering

**Solution:**
```powershell
# Check if Three.js is installed
npm list three

# Reinstall if needed
npm install three@latest
```

### Issue: Slow Performance

**Solution:**
```env
# Reduce star LOD and particle count
REACT_APP_STAR_LOD=medium
REACT_APP_PARTICLE_COUNT=25000
```

### Issue: Azure Connection Error

**Solution:**
```powershell
# Test Azure storage connection
curl -I "https://networkbusterdata.blob.core.windows.net/galaxy-data/stars.json"

# Check CORS configuration
az storage cors list --account-name networkbusterdata --services b
```

### Issue: Travel Calculations Incorrect

**Solution:**
```javascript
// Verify constants in aerospace-calculations.js
const LIGHT_SPEED = 299792.458; // km/s (exact)
const LIGHT_YEAR = 9460730472580800; // meters (exact)
```

---

## 📚 Additional Resources

- **Three.js Documentation:** https://threejs.org/docs/
- **React Three Fiber Docs:** https://docs.pmnd.rs/react-three-fiber/
- **NASA Exoplanet Archive:** https://exoplanetarchive.ipac.caltech.edu/
- **Gaia Space Telescope:** https://www.esa.int/gaia
- **SIMBAD Astronomical Database:** http://simbad.u-strasbg.fr/

---

## 📋 Support & Maintenance

**Version:** 1.0  
**Last Updated:** December 14, 2025  
**Maintainer:** NetworkBuster Team  
**Status:** ✅ Production Ready

For issues or feature requests, create a GitHub issue in the networkbuster.net repository.

---

**Galaxy Navigation System Integration Complete!** 🌌
