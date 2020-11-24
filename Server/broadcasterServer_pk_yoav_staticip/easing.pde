float easeOutSine(float x) {
    return sin((x * PI) / 2);
}

float easeInSine(float x) {
    return 1 - cos((x * PI) / 2);
}

float easeSineAndBack(float x) {
    return sin(x * PI);
}

float GOAL_TOLERANCE = 20;

boolean adjustPressureTo(float goal, Measurement values) {
    if (values.pressure1 != 0.0) adjustPressure(values.pressure1, goal, 1);
    if (values.pressure2 != 0.0) adjustPressure(values.pressure2, goal, 2);
    if (values.pressure3 != 0.0) adjustPressure(values.pressure3, goal, 3);
    if (values.pressure4 != 0.0) adjustPressure(values.pressure4, goal, 4);
    if (values.pressure5 != 0.0) adjustPressure(values.pressure5, goal, 5);
    if (values.pressure6 != 0.0) adjustPressure(values.pressure6, goal, 6);
    if (values.pressure7 != 0.0) adjustPressure(values.pressure7, goal, 7);
    if (values.pressure8 != 0.0) adjustPressure(values.pressure8, goal, 8);
    if (values.pressure9 != 0.0) adjustPressure(values.pressure9, goal, 9);
    if (values.pressure10 != 0.0) adjustPressure(values.pressure10, goal, 10);

    return ((values.pressure1 == 0.0 || abs(values.pressure1 - goal) <= GOAL_TOLERANCE )
            && (values.pressure2 == 0.0 || abs(values.pressure2 - goal) <= GOAL_TOLERANCE )
            && (values.pressure3 == 0.0 || abs(values.pressure3 - goal) <= GOAL_TOLERANCE )
            && (values.pressure4 == 0.0 || abs(values.pressure4 - goal) <= GOAL_TOLERANCE )
            && (values.pressure5 == 0.0 || abs(values.pressure5 - goal) <= GOAL_TOLERANCE )
            && (values.pressure6 == 0.0 || abs(values.pressure6 - goal) <= GOAL_TOLERANCE )
            && (values.pressure7 == 0.0 || abs(values.pressure7 - goal) <= GOAL_TOLERANCE )
            && (values.pressure8 == 0.0 || abs(values.pressure8 - goal) <= GOAL_TOLERANCE )
            && (values.pressure9 == 0.0 || abs(values.pressure9 - goal) <= GOAL_TOLERANCE )
            && (values.pressure10 == 0.0 || abs(values.pressure10 - goal) <= GOAL_TOLERANCE )
            );
}

void adjustPressure(float current, float goal, int device){
    float diff = current - goal;
    float a = -0.007;
    float b = -1.2;
    float c = 5.0;
    float adjustment = (current < goal + (GOAL_TOLERANCE / 4.0) || current > goal + GOAL_TOLERANCE)
        ? (a * abs(diff) * diff) + (b * diff) + c
        : 0.0;
    sendTo(device, adjustment);
}
