#define PI 3.1415926


uniform int uNumAgent;
uniform float uMoveSpeed;
uniform float uDeltaTime;
uniform float uTime;
uniform vec2 uRes;
//uniform int uNumSettings;



struct Agent{
	vec2 position;
	float angle;
	//ivec2 speciesMask;
	int speciesIndex;

};

struct SpeciesSettings { // How to do multi settings ??
	// There is a texture buffer in TD
		//group 1
	float sensorAngle;
		//group 2
	float moveSpeed;
	float turnSpeed;
		//group 3
	float sensorOffsetDst;
	int sensorSize;
		//group 4
	vec3 color;
};
//-----------------------------------------------------------------------------------------------

// One species Test version
float sense(Agent agent, float sensorAngleOffset, SpeciesSettings settings){
	float sensorAngle = agent.angle + sensorAngleOffset;
	vec2 sensorDir = vec2(cos(sensorAngle), sin(sensorAngle));
	vec2 sensorPos = agent.position + sensorDir * settings.sensorOffsetDst;
	 // need to map the value to the trail map size !!
	int sensorCentreX = int(ceil(sensorPos.x) + uRes.x);
	int sensorCentreY = int(ceil(sensorPos.y) + uRes.y);


	float sum = 0;
	// Sense Weight : 
	//vec2 senseWeight = agent.speciesMask * 2 - 1;

	for (int offsetX = -settings.sensorSize; offsetX <= settings.sensorSize; offsetX++){
		for (int offsetY = -settings.sensorSize; offsetY <= settings.sensorSize; offsetY++){
			int sampleX = min(int(uRes.x * 2 - 1), max(0, sensorCentreX + offsetX));
 			int sampleY = min(int(uRes.y * 2 - 1), max(0, sensorCentreY + offsetY));
			sum += texelFetch(sTD2DInputs[2], ivec2(sampleX, sampleY), 0).r;
			
		}
	}


	return sum;
}


//-----------------------------------------------------------------------------------------------


layout(std430, binding = 0) buffer agentBuffer{
	Agent agents[];
};

layout(std430, binding = 0) buffer settingBuffer{
	SpeciesSettings speciesSettings[];
};

layout (local_size_x = 8, local_size_y = 8) in;
void main()
{
	// TD Feedback Loop Buffer
	vec2 pos = texelFetch(sTD2DInputs[0], ivec2(gl_GlobalInvocationID.xy), 0).rg;
	float ang = texelFetch(sTD2DInputs[1], ivec2(gl_GlobalInvocationID.xy), 0).a;
	
	uint id = gl_GlobalInvocationID.y * int(uTDOutputInfo.res.x) + gl_GlobalInvocationID.x;
	if (id >= uNumAgent) { return;}
	Agent agent = agents[id];
	agent.position = pos;
	agent.angle = mod(ang,2*PI);

	// Species Settings data Setup
	vec2 speedBuffer = texelFetch(sTD2DInputs[3], ivec2(gl_GlobalInvocationID.xy), 0).rg;
	float sensorAngle = texelFetch(sTD2DInputs[4], ivec2(gl_GlobalInvocationID.xy), 0).r;
	float sensorOffsetDst = texelFetch(sTD2DInputs[5], ivec2(gl_GlobalInvocationID.xy), 0).r;
	float sensorSize = texelFetch(sTD2DInputs[6], ivec2(gl_GlobalInvocationID.xy), 0).r;
	vec3 color = texelFetch(sTD2DInputs[7], ivec2(gl_GlobalInvocationID.xy), 0).rgb;
	
	SpeciesSettings settings = speciesSettings[id]; // map to different settings, but how to define the structured data ??
	settings.sensorAngle = sensorAngle;
	settings.color = color;
	settings.moveSpeed = speedBuffer.r;
	settings.turnSpeed = speedBuffer.g;
	settings.sensorOffsetDst = sensorOffsetDst;
	settings.sensorSize = int(sensorSize);


	

	// Steer based on sensory data
	// float sensorAngleRad = settings.sensorAngleDegrees * (3.1415 / 180);
	// float weightForward = sense(agent, settings, 0);
	// float weightLeft = sense(agent, settings, sensorAngleRad);
	// float weightRight = sense(agent, settings, -sensorAngleRad);

	float sensorAngleRad = settings.sensorAngle * PI / 180;
	float weightForward = sense(agent, 0, settings);
	float weightLeft = sense(agent, sensorAngleRad, settings);
	float weightRight = sense(agent, -sensorAngleRad, settings);

	float randomSteerStrength = TDSimplexNoise(agent.position);
	float turnSpeed = settings.turnSpeed * 2 * PI;

	// Moving Direction Settings
		// Continue in same direction
	if (weightForward > weightLeft && weightForward > weightRight) {
		agent.angle += 0;

	}
	else if (weightForward < weightLeft && weightForward < weightRight) {
		agent.angle += (randomSteerStrength - 0.5) * 2 * turnSpeed * uDeltaTime;
    	
	}
		//Turn Right
	else if (weightRight > weightLeft) {
		agent.angle -= randomSteerStrength * turnSpeed * uDeltaTime;
	}
		//Turn Left
	else if (weightLeft > weightRight) {
		agent.angle += randomSteerStrength * turnSpeed * uDeltaTime;
	}

	
	vec2 direction = vec2(cos(agent.angle), sin(agent.angle));

	

	//Clamp position to map boundaries
	if (agent.position.x > uRes.x || agent.position.x < -uRes.x || agent.position.y > uRes.y || agent.position.y < -uRes.y){
		float dx = abs(agent.position.x) - abs(uRes.x);
		float dy = abs(agent.position.y) - abs(uRes.y);
		agent.position.x =  min(uRes.x - dx,max(dx - uRes.x, agent.position.x));
		agent.position.y = min(uRes.y - dy ,max(dy - uRes.y, agent.position.y));
		//agent.velocity *= -1;
		agent.angle =  TDSimplexNoise (agent.position) * 2.0 * PI;
	}

	// Move agent
	agent.position += direction * uDeltaTime * settings.moveSpeed * uMoveSpeed;

	

	


	
	imageStore(mTDComputeOutputs[0], ivec2(gl_GlobalInvocationID.xy), TDOutputSwizzle(vec4(agent.position,0,0)));
	imageStore(mTDComputeOutputs[1], ivec2(gl_GlobalInvocationID.xy), TDOutputSwizzle(vec4(settings.color, agent.angle)));


}


