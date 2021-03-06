
/**
* @class Vessel
* @desc Transport vessel/vehicle
*/

class Vessel 
{
	
	Route route;

	private int destIndex = 0;
	boolean terminated = false;
	float _x;
	float _y;
	float linkLength;
	float routeLengthPx;
	private float speed;

	Point destCoords;
	Point originCoords;
	Stop dest;
	Stop origin;			
	String[] stops;
	Trip trip;
	int journeyNum = 1;
	int nullStops = 0;
	
	float xDist;
	float yDist;
	float edgeLength;
	
	public Vessel(Route route) {
		this.route = route;		
		this.stops = this.route.getStops().clone();
		//debug("created vessel on " + route.name + " route");
		this._x = 0;
		this._y = 0;
      this.setSpeed(BUS_SPEED);		  
	}
	
	public Vessel(Trip trip) {
	  this.route = trip.getRoute();
	  this.trip = trip;
	  this.stops = this.route.getStops().clone();
		//debug("created vessel on " + route.name + " route");
		this._x = 0;
		this._y = 0;
		this.routeLengthPx = this.route.getRouteLengthPixels();
		Float f = new Float((this.routeLengthPx/trip.getDuration())*net.getTripSpeed());
    this.setSpeed(f);
    debug("speed is "+ this.speed);
	}
	
	private void placeAtOrigin()
	{
		this.refreshDestination();
		
		if(this.terminated) return;
		
		if(this.dest == null) {
			this.nullStops++;			
			this.setNextDest();
		 if(!this.terminated) {
			 this.placeAtOrigin(); 
		 } else {
			debug("NO ORIGIN FOR ROUTE " + this.route.name); 
		 }
		 
		 return;
		}
		
		this.originCoords = dest.getCoords();
		this.origin = dest;
		this._x = this.originCoords.x;
		this._y = this.originCoords.y;
		//debug(this.dest.getId() + " origin");		
		this.drawme(); 
	}
	
	public boolean atDepot() 
	{
	 return (this._x == 0);
	}
	
	public void update() {
		if(this.atDepot() && !this.terminated) this.placeAtOrigin();
		if(this.origin == null) return;				
				
		if(dest == null) {
			this.setNextDest();
			this.nullStops++;
			//debug(destID+" doesnt exist\n");			
			return;
		}
		
		this.moveToDest();
		
		if(this.atDest()) {
				this.setNextDest();
				//this.printTrajectory();
			} 
		this.drawme();
	}
	
	private void setSpeed(float speed) {
	  this.speed = speed;
	}
	
	private void printTrajectory()
	{ 
				if(!(dest == null)) {
					print("drawing vessel on " + this.route.name +" with dest " + dest.getId() + " " + destCoords.x + "," + destCoords.y + "\n");			
					//dest.printme();
					//this.route.printme();			
				}
	}
	
	private void moveToDest()
	{
		float xdiff,ydiff;
		if(net.isInTripsMode()) {
        this.edgeLength = (this.linkLength > 0) ? this.linkLength : this.routeLengthPx;		  
  			xdiff = this.xDist * this.speed/edgeLength;
  			ydiff = this.yDist * this.speed/edgeLength;        
		}
		else if(cp.dynamics == ControlPanel.SWARM) {
			xdiff = (this.destCoords.x - this._x) * this.speed;
			ydiff = (this.destCoords.y - this._y) * this.speed;
		} else {
			if(!this.beyondMidPoint()) { //accelerate to midpoint
				xdiff = 0.05 + this.distanceFromOrigin() * this.speed/80;				
				ydiff = 0.05 + this.distanceFromOrigin() * this.speed/80;
			} else { //decelerate to dest
				xdiff = (this.destCoords.x - this._x) * this.speed;
				ydiff = (this.destCoords.y - this._y) * this.speed;
			}
		}
		
		if(!net.isInTripsMode()) {
		  if(abs(xdiff) > MAX_SPEED) xdiff *= MAX_SPEED/abs(xdiff);
		  if(abs(ydiff) > MAX_SPEED) ydiff *= MAX_SPEED/abs(ydiff);
	  }
		
		this._x += xdiff;
		this._y += ydiff;				
	}
	
	private boolean beyondMidPoint()
	{
		return this.distanceFromOrigin() > (this.linkLength/2);
	}
	
	private float distanceFromDest()
	{
			return sqrt(pow(abs(this.dest._x - this._x),2) + pow(abs(this.dest._y - this._y),2));			 
	}
	
	private float distanceFromOrigin()
	{
		if(this.origin != null) {
			return sqrt(pow(abs(this._x - this.origin._x),2) + pow(abs(this._y - this.origin._y),2));	 
		} else {
			return 0;
		}
	}
	
	private void refreshDestination()
	{
		String destID = this.getStops()[destIndex];				
		Stop destStop = (Stop) net.aStop.get(ltrim(destID));
		if(destStop != null) {
			this.setDestination(destStop);
		}
	}
	
	private Stop getDestination()
	{
		 return this.dest; 
	}
	
	public void setDestinationIndex(int index)
	{
		 this.destIndex = index; 
	}
	
	private void setDestination(Stop dest)
	{
	 this.dest = dest;
	 this.destCoords = dest.getCoords(); 
	}

    private void calcLinkLength()
    {
        if(this.origin != null) {
            this.linkLength = sqrt(pow(abs(this.dest._x - this.origin._x),2) + pow(abs(this.dest._y - this.origin._y),2));
        }
    }

    public void setNextDest()
    {
        if(destIndex < this.getStops().length-1) {
            Stop orig = this.getDestination();
            if(orig != null) this.origin = orig;
            this.originCoords = this.origin.getCoords();
            destIndex++;
            this.refreshDestination();
            this.calcLinkLength();	            
            if(net.isInTripsMode()) {
      		    this.xDist = this.destCoords.x - this.originCoords.x;
        		  this.yDist = this.destCoords.y - this.originCoords.y;
              //debug("linkdist "+ this.linkLength + " " + this.routeLengthPx);
            }
            
            if(cp.dynamics == ControlPanel.BUS) {
                this.calcLinkLength();	
            }
            } else {
                terminated = true;
                if((this.getStops().length - this.nullStops) > 4) {
                    if(this.journeyNum < 3 && net.isIncrementalGrowth()) {
                        net.createVessel(this.route);
                    }
                }

                if(net.peaked && net.isIncrementalGrowth()) {
                    net.removeVessel(); 
                    net.removeVessel();
                }

                this.journeyNum++;
                destIndex = 0;										
                this.reverseStops();						
                this.route.nullStops = this.nullStops;
                this.nullStops = 0;
                //this.refreshDestination();
        }
    }
	
	private void reverseStops()
	{
		String[] cstops = this.stops.clone();
		List<String> sttops = Arrays.asList(cstops);
		Collections.reverse(sttops);
		this.stops = (String[]) sttops.toArray();
	}
	
	private String[] getStops()
	{
		return this.stops;
	}
	
	public void drawme()
	{
		int alphax = trails ? 7 : 30;
		fill(#FFFFFF,alphax);
		stroke(#FFFFFF,alphax);		
		
    if(net.isInTripsMode() && this.journeyNum > 1) {
      return;//no render
    }
		
		ellipse(this._x + net.getXOffset(),this._y - net.getYOffset(),1,1);	
	}

	private boolean atDest(){
		 return (abs(this.destCoords.x - this._x) < 1 && abs(this.destCoords.y - this._y) < 1); 
	}	
}
