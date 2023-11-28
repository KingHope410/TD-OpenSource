#define INITPOS 0
#define INITVEL 1
#define WHALEPOS 2
#define HUNIPOS 3
#define NUM_FOODS 5



uniform vec4 uMapSize;
uniform float uFrameStep;
uniform float uFlockDist; // check distance
uniform vec4 uRuleWeight;// x: Alignment y: Cohesion z: Speration w: Center

//Bounds
uniform vec3 uLimitPos;
uniform vec3 uLimitNeg;

//SpeedLimit
uniform float uSpeedLimit;
uniform float uSpeedVariance;

//Attractor
uniform vec3 uAttractor;
uniform float uAttraction;

//Foods : Attractors
uniform vec4 uFoods[NUM_FOODS];
uniform float uFoodAttraction;

//Predator
uniform vec3 uPredator;

//whale Predator
uniform float uPredatorWhale;


// instance Data
out vec4 positionData;
out vec4 velocityData;


//--------------Boid Struct----------------
struct Boid
{
	vec3 position;
	vec3 velocity;
	vec3 acceleration;
};


//--------------Boid Rules-----------------
//Alignment Function
vec3 Align(vec3 my_velocity, vec3 nearest_flock_velocity, int nearest_flock_members)
{	
	vec3 steer = (nearest_flock_members)*nearest_flock_velocity/(length(nearest_flock_velocity)+0.05) - my_velocity;
	return steer*uRuleWeight.x;
}


//Cohesion Function
vec3 Cohesion(vec3 my_position, vec3 nearest_flock_position, int nearest_flock_members)
{
	vec3 steer = nearest_flock_position/(nearest_flock_members+0.05) - my_position;
	return steer*uRuleWeight.y;
}

//Speration Function
vec3 Speration(vec3 my_position, vec3 nearest_flock_difference, int nearest_flock_members)
{
	vec3 steer = nearest_flock_difference/(nearest_flock_members+0.05) - my_position;
	return steer*uRuleWeight.z;
}

//Predator Function
vec3 Predator(vec3 my_position,vec4 predator_pos)
{
	float dis = distance(my_position,predator_pos.xyz);
	vec3 steer = (predator_pos.xyz - my_position)/dis;
	return -steer/(dot(steer,steer)+0.05) * uRuleWeight.w * predator_pos.w;
}

vec3 PredatorWhale(vec3 my_position,vec3 predator_pos)
{
	float dis = distance(my_position,predator_pos);
	vec3 steer = (predator_pos - my_position)/dis;
	return -steer/(dot(steer,steer)+0.05) * uPredatorWhale;
}


//-------------Flocking Stuff---------------
vec3 flocking(vec3 my_position, vec3 my_velocity, vec3 whalePos, vec4 huntPos)
{
	//受力
	vec3 acceleration = vec3(0);
	// 附近的boid
	int nearest_flock_members = 0;
	// 附近Boid的速度求和
	vec3 nearest_flock_velocity = vec3(0);
	// 附近Boid的位置求和
	vec3 nearest_flock_position = vec3(0);
	// 附近Boid的排斥
	vec3 nearest_flock_difference = vec3(0);


	// 选择对应追逐的食物
	vec2 my_coords = vUV.st * uMapSize.zw;
    float my_attr = my_coords.x * my_coords.y;
    my_attr = mod(my_attr, NUM_FOODS);



	for(int i = 0; i < uMapSize.z; i++)
	{
		for(int j = 0; j< uMapSize.w; j++)
		{
			vec2 them = vec2( (float(i) * uMapSize.x) + (uMapSize.x/2), float(j) * uMapSize.y + (uMapSize.y/2));
			vec3 their_position = texture(sTD2DInputs[INITPOS], them).xyz;
            vec3 their_velocity = texture(sTD2DInputs[INITVEL], them).xyz;


			float dis = distance(my_position, their_position);

			//检测距离判断
			if(dis < uFlockDist && them != vUV.st)
			{
				nearest_flock_members += 1;
				nearest_flock_position += their_position;
				nearest_flock_velocity += their_velocity;
				nearest_flock_difference += (my_position - their_position) / dis;
				
				if(nearest_flock_members > 0)
				{
					//Alignment
					acceleration += Align(my_velocity, nearest_flock_velocity,nearest_flock_members);
					//Cohesion
					acceleration += Cohesion(my_position,nearest_flock_position,nearest_flock_members);
					//Speration
					acceleration += Speration(my_position,nearest_flock_difference,nearest_flock_members);
					//Predator
					acceleration += Predator(my_position, huntPos);
					acceleration += PredatorWhale(my_position, whalePos);

				} 

			}


		}
	}


	//Food Attractor
	vec3 foods = uFoods[int(my_attr)].xyz;
	if(uFoods[int(my_attr)].w != 0) acceleration += normalize(foods - my_position)*uFoodAttraction;
	
	//Main Attractor
	vec3 goal = uAttractor;
	if(goal != vec3(0.0)) acceleration += normalize(goal - my_position)*uAttraction;

	return acceleration;
}

//---------------Speed Control---------------------
vec3 speedlimit( float variance, vec3 velocity)
{
    float my_limit = uSpeedLimit + (variance * uSpeedVariance);
    if (length(velocity) > my_limit)
        velocity = normalize(velocity) * my_limit;
    return velocity;
}



///////////////////////////////////////////////////////////
void main()
{
	Boid boid;
	//初始位置与速度
	vec3 pos = texture(sTD2DInputs[INITPOS], vUV.st).xyz;
	vec3 vel = texture(sTD2DInputs[INITVEL], vUV.st).xyz;
	//鲸鱼位置
	vec3 whalePos = texture(sTD2DInputs[WHALEPOS],vUV.st).xyz;
	//捕鱼位置及激活
	vec4 huntPos = texture(sTD2DInputs[HUNIPOS],vUV.st);
	//变化量：速度变化与大小变化
	float variance = abs(texture(sTD2DInputs[INITPOS], vUV.st).w);
	variance = max(variance,0.25);

	//更新位置与速度
	boid.position = pos + vel * uFrameStep;
	//boid.acceleration = flocking(boid.position, vel, whalePos);
	boid.velocity = vel + flocking(boid.position, vel, whalePos, huntPos);
	//boid.velocity += boid.acceleration;

	//加入位置扰动

	//限制速度
	boid.velocity = speedlimit(variance,boid.velocity);
	
	
	// is the point offscreen?
	if (boid.position.x > uLimitPos.x || boid.position.x < uLimitNeg.x) boid.position.x *= -1;
	if (boid.position.y > uLimitPos.y || boid.position.y < uLimitNeg.y) boid.position.y *= -1;
	if (boid.position.z > uLimitPos.z || boid.position.z < uLimitNeg.z) boid.position.z *= -1;

	//输出数据
	positionData = TDOutputSwizzle(vec4(boid.position,variance));
	velocityData = TDOutputSwizzle(vec4(boid.velocity,1));

}



