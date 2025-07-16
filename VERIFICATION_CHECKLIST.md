# FrancoSphere v6.0 Debug Fix Verification Checklist

## ✅ P0 - Critical Data-Load & State Failures

### 1. WorkerContextEngine Portfolio Access
- [ ] Workers can access both assigned and portfolio buildings
- [ ] Kevin sees 8 buildings with Rubin Museum as PRIMARY
- [ ] Database queries work without errors
- [ ] Clock-in status loads correctly

### 2. Database Seeding with Portfolio Logic
- [ ] Kevin has correct building assignments (including Rubin Museum)
- [ ] All 7 workers have proper assignments
- [ ] Portfolio access logic works
- [ ] Database sanity check passes

### 3. ClockInManager Portfolio Access
- [ ] Workers can clock in at ANY building
- [ ] No building validation restrictions
- [ ] Both assigned and portfolio buildings available
- [ ] Clock-in notifications work

### 4. Database Sanity Check
- [ ] Debug logging shows correct assignments
- [ ] Kevin specifically assigned to Rubin Museum
- [ ] Worker counts are accurate
- [ ] No database errors

## ✅ P1 - UI/UX Wiring Issues

### 1. WorkerContextEngineAdapter Portfolio Support
- [ ] Exposes both assigned and portfolio buildings
- [ ] Building type classification works
- [ ] Real-time updates for both types
- [ ] Primary building detection works

### 2. Generic AI Icon in Header
- [ ] AI icon hidden for worker roles
- [ ] Enhanced role descriptions show
- [ ] Header layout and spacing correct
- [ ] Profile section works properly

### 3. Portfolio Access UI Implementation
- [ ] Clock-in shows all buildings for coverage
- [ ] "My Buildings" shows only assigned
- [ ] Building selection modes work
- [ ] Coverage access is clear

### 4. Today's Progress Card 0/0 Fix
- [ ] Shows real task numbers (not 0/0)
- [ ] Progress calculation works
- [ ] Real-time updates on task completion
- [ ] Percentage displays correctly

## ✅ P2 - Cosmetic/Layout Issues

### 1. PropertyCard Theme Issues
- [ ] Building images load with fallbacks
- [ ] Dark mode compatibility
- [ ] Copy changed from "My Sites" to "Portfolio"
- [ ] All building IDs have proper image mapping

### 2. Dark Mode Sheet Issues
- [ ] Empty states show proper styling
- [ ] Background colors consistent
- [ ] Text visibility in dark mode
- [ ] Navigation works properly

## 🎯 Overall Success Criteria

### User Experience Validation
- [ ] Kevin sees 8 buildings with Rubin Museum PRIMARY
- [ ] Edwin sees park operations clearly
- [ ] Coverage scenarios work seamlessly
- [ ] Emergency access never blocked
- [ ] Progressive disclosure works

### Technical Integration
- [ ] No compilation errors
- [ ] Database queries work
- [ ] Real-time synchronization maintained
- [ ] Actor patterns preserved
- [ ] Performance acceptable

### Architecture Benefits
- [ ] Zero breaking changes
- [ ] Enhanced UX maintained
- [ ] Real-world workflow optimization
- [ ] Production-ready state achieved

## 📊 Success Metrics

### Before Fixes (Issues)
- [ ] WorkerContextError error 1 red banner
- [ ] Worker name not appearing in header
- [ ] Clock-in shows empty building list
- [ ] "My Sites" opens empty map
- [ ] Today's Progress shows 0/0
- [ ] Profile shows 0 buildings

### After Fixes (Expected)
- [ ] Worker name appears correctly
- [ ] Clock-in shows portfolio buildings
- [ ] "My Buildings" opens building list
- [ ] Today's Progress shows real numbers
- [ ] No red error banners
- [ ] Profile shows correct building count
- [ ] Map pins appear for buildings

## 🚀 Final Deployment Checklist

- [ ] All P0 issues resolved
- [ ] All P1 issues resolved  
- [ ] All P2 issues resolved
- [ ] Integration tests pass
- [ ] Performance acceptable
- [ ] User acceptance testing complete
- [ ] Documentation updated
- [ ] Ready for production deployment

**Target Status: 92% → 96% Complete (Production Ready)**
