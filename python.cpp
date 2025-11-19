#include <string>
#include <time.h>
#define FREEGLUT_STATIC
#include <GL/freeglut.h>
#include <cmath>

#using namespace std;


int N = 30, M = 20;
int Scale = 25;
int w = Scale * N;
int h = Scale * M;
int dir = 0, num = 4;
int level = 1;
int score = 0;
int base_speed = 200;
int current_speed = 200;
const int WIN_SCORE = 50;  


float textAlpha = 1.0f;
float hueShift = 0.0f;
bool isCongratShowing = false;
bool gameWon = false;
int congratStartTime = 0;

struct pytonchik { int x, y; } s[160];      

class Fructs {
public:
    int xr, yr;

   
    void New(pytonchik* snake, int snakeLength) {
        bool validPosition;
        do {
            validPosition = true;
           
            xr = rand() % N;
            yr = rand() % M;

            
            for (int j = 0; j < snakeLength; j++) {
                if (snake[j].x == xr && snake[j].y == yr) {
                    validPosition = false;
                    break;
                }
            }
        } while (!validPosition); 
    }

    void DrawApple();
} m[10];


void DrawCircle(float cx, float cy, float radius);  
void position();
void DrawField();
void Tick();
void DrawPyton();
void MyKeyboard(int key, int a, int b);
void display();
void timer(int value);
void DrawScore();
void DrawCongrat();
void congratAnimation(int value);
void congrat();
void HSVtoRGB(float h, float s, float v, float& r, float& g, float& b);
void ResetGame();


void DrawCircle(float cx, float cy, float radius) {
    const int segments = 32;
    glBegin(GL_TRIANGLE_FAN);
    glVertex2f(cx, cy); 
    for (int i = 0; i <= segments; i++) {
        float angle = 2.0f * 3.14159f * i / segments;
        glVertex2f(cx + radius * cos(angle),
                   cy + radius * sin(angle));
    }
    glEnd();
}


void position() {
    
    s[0].x = 15;
    s[0].y = 10;
    for (int i = 0; i < num; i++) {
        s[i].x = 15;
        s[i].y = 10 - i;
    }
}

void ResetGame() {
    score = 0;
    level = 1;
    num = 4;
    current_speed = base_speed;
    dir = 0;
    position();
    isCongratShowing = false;
    gameWon = false;
    textAlpha = 1.0f;
    hueShift = 0.0f;

    for (int i = 0; i < 10; i++) {
        m[i].New(s, num); 
    }
}

void HSVtoRGB(float h, float s, float v, float& r, float& g, float& b) {
    int i = static_cast<int>(h * 6);
    float f = h * 6 - i;
    float p = v * (1 - s);
    float q = v * (1 - f * s);
    float t = v * (1 - (1 - f) * s);

    switch (i % 6) {
        case 0: r = v; g = t; b = p; break;
        case 1: r = q; g = v; b = p; break;
        case 2: r = p; g = v; b = t; break;
        case 3: r = p; g = q; b = v; break;
        case 4: r = t; g = p; b = v; break;
        case 5: r = v; g = p; b = q; break;
    }
}

void DrawCongrat() {
    if (!isCongratShowing) return;

    glMatrixMode(GL_PROJECTION);
    glPushMatrix();
    glLoadIdentity();
    gluOrtho2D(0, w, 0, h);

    glMatrixMode(GL_MODELVIEW);
    glPushMatrix();
    glLoadIdentity();

    glEnable(GL_BLEND);
    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);

    string text = "Congratulations! Collected " + to_string(score) + " apples!";
    string text2 = "You Critical Win! Level: " + to_string(level);

    
    int textWidth = 0;
    for (char c : text) {
        textWidth += glutBitmapWidth(GLUT_BITMAP_HELVETICA_18, c);
    }

    int textWidth2 = 0;
    for (char c : text2) {
        textWidth2 += glutBitmapWidth(GLUT_BITMAP_HELVETICA_18, c);
    }

    
    glColor4f(0.0f, 0.0f, 0.0f, textAlpha * 0.7f);
    glRasterPos2i((w - textWidth)/2 + 3, h/2 - 3);
    for (char c : text) {
        glutBitmapCharacter(GLUT_BITMAP_HELVETICA_18, c);
    }

    glRasterPos2i((w - textWidth2)/2 + 3, h/2 - 33);
    for (char c : text2) {
        glutBitmapCharacter(GLUT_BITMAP_HELVETICA_18, c);
    }

   
    float r, g, b;
    HSVtoRGB(hueShift, 1.0f, 1.0f, r, g, b);
    glColor4f(r, g, b, textAlpha);
    glRasterPos2i((w - textWidth)/2, h/2);
    for (char c : text) {
        glutBitmapCharacter(GLUT_BITMAP_HELVETICA_18, c);
    }

    glRasterPos2i((w - textWidth2)/2, h/2 - 30);
    for (char c : text2) {
        glutBitmapCharacter(GLUT_BITMAP_HELVETICA_18, c);
    }

    glDisable(GL_BLEND);
    glPopMatrix();
    glMatrixMode(GL_PROJECTION);
    glPopMatrix();
    glMatrixMode(GL_MODELVIEW);
}

void congratAnimation(int value) {
    if (!isCongratShowing) return;

    int elapsed = glutGet(GLUT_ELAPSED_TIME) - congratStartTime;

    if (elapsed < 7000) {
        hueShift = fmod(static_cast<float>(elapsed) / 2000.0f, 1.0f);
    }
    else if (elapsed < 9000) {
        textAlpha = 1.0f - static_cast<float>(elapsed - 7000) / 2000.0f;
    }
    else {
        isCongratShowing = false;
        gameWon = false;
        textAlpha = 1.0f;

      
        ResetGame();
        return;
    }

    glutTimerFunc(16, congratAnimation, 0);
    glutPostRedisplay();
}

void congrat() {
    isCongratShowing = true;
    gameWon = true;
    congratStartTime = glutGet(GLUT_ELAPSED_TIME);
    textAlpha = 1.0f;
    glutTimerFunc(16, congratAnimation, 0);
}

void DrawScore() {
    string levelStr = "Level: " + to_string(level);
    string scoreStr = "Apples: " + to_string(score);
    string nextLevelStr = "Next level at: " + to_string(10 * level);
    string winScoreStr = "Win at: " + to_string(WIN_SCORE);

    glMatrixMode(GL_PROJECTION);
    glPushMatrix();
    glLoadIdentity();
    gluOrtho2D(0, w, 0, h);

    glMatrixMode(GL_MODELVIEW);
    glPushMatrix();
    glLoadIdentity();

    
    glColor3f(1.0, 0.5, 0.0);
    glRasterPos2i(10, h - 20);
    for (char c : levelStr) {
        glutBitmapCharacter(GLUT_BITMAP_HELVETICA_12, c);
    }

   
    glColor3f(1.0, 1.0, 1.0);
    glRasterPos2i(10, h - 40);
    for (char c : scoreStr) {
        glutBitmapCharacter(GLUT_BITMAP_HELVETICA_12, c);
    }

    
    glColor3f(0.5, 1.0, 0.5);
    glRasterPos2i(10, h - 60);
    for (char c : nextLevelStr) {
        glutBitmapCharacter(GLUT_BITMAP_HELVETICA_12, c);
    }

    
    glColor3f(1.0, 0.5, 0.5);
    glRasterPos2i(10, h - 80);
    for (char c : winScoreStr) {
        glutBitmapCharacter(GLUT_BITMAP_HELVETICA_12, c);
    }

    glPopMatrix();
    glMatrixMode(GL_PROJECTION);
    glPopMatrix();
    glMatrixMode(GL_MODELVIEW);
}

void DrawField() {
    glColor3f(0.2, 0.2, 0.2);
    glLineWidth(1.5);

    glBegin(GL_LINES);
    
    for (int i = 0; i <= N; i++) {
        float x = i * Scale;
        glVertex2f(x, 0);
        glVertex2f(x, h);
    }
    
    for (int j = 0; j <= M; j++) {
        float y = j * Scale;
        glVertex2f(0, y);
        glVertex2f(w, y);
    }
    glEnd();
}

void Tick() {
    if (gameWon) return;

  
    for (int i = num; i > 0; --i) {
        s[i].x = s[i-1].x;
        s[i].y = s[i-1].y;
    }

   
    if (dir == 0) s[0].y += 1;    
    else if (dir == 1) s[0].x -= 1; 
    else if (dir == 2) s[0].x += 1; 
    else if (dir == 3) s[0].y -= 1

   
    for (int i = 0; i < 10; i++) {
       
        if ((s[0].x == m[i].xr) && (s[0].y == m[i].yr)) {
            num++; 
            score++;
            m[i].New(s, num); 

           
            if (score == WIN_SCORE) {
                congrat();
                return;
            }

            
            if (score == 10 * level) {
                level++;
                score = 0;  
                current_speed -= 20;
                if (current_speed < 50) current_speed = 50;
            }
        }
    }

    
    for (int i = 1; i < num; i++) {
        if (s[0].x == s[i].x && s[0].y == s[i].y) {
            num = i; 
            score = 0;
            break;
        }
    }

    
    if (s[0].x + 1 > N) dir = 1; 
    if (s[0].x < 0) dir = 2;     
    if (s[0].y + 1 > M) dir = 3;
    if (s[0].y < 0) dir = 0;     
}


void DrawPyton() {
    glColor3f(0.0, 0.0, 1.0)
    for (int i = 0; i < num; i++) {
        float centerX = s[i].x * Scale + Scale / 2.0f;
        float centerY = s[i].y * Scale + Scale / 2.0f;
        DrawCircle(centerX, centerY, Scale / 2.0f * 0.95f); 
    }
}


void Fructs::DrawApple() {
    glColor3f(0.0, 1.0, 0.0); // Зеленый цвет
    float centerX = xr * Scale + Scale / 2.0f;
    float centerY = yr * Scale + Scale / 2.0f;
    DrawCircle(centerX, centerY, Scale / 2.0f * 0.95f); 
}

void MyKeyboard(int key, int a, int b) {
   
    switch(key) {
        case GLUT_KEY_UP:    dir = 0; break; 
        case GLUT_KEY_RIGHT: dir = 2; break; 
        case GLUT_KEY_LEFT:  dir = 1; break; 
        case GLUT_KEY_DOWN:  dir = 3; break; 
    }
}

void display() {
    glClear(GL_COLOR_BUFFER_BIT);

    DrawField();

    
    for (int i = 0; i < 10; i++)
        m[i].DrawApple();

    DrawPyton();
    DrawScore(); 

    
    if (isCongratShowing) {
        DrawCongrat();
    }

    
    glutSwapBuffers();
}

void timer(int value) {
    Tick();
    glutPostRedisplay();
    glutTimerFunc(current_speed, timer, 0);
}

int main(int argc, char **argv) {
    srand(time(0)); 
    ResetGame(); 

    glutInit(&argc, argv);

    
    glutInitDisplayMode(GLUT_DOUBLE | GLUT_RGBA | GLUT_MULTISAMPLE);
    glutInitWindowSize(w, h);
    glutInitWindowPosition(200, 200);

    
    glEnable(GLUT_MULTISAMPLE);

   
    glutSetOption(GLUT_MULTISAMPLE, 8); 

    glutCreateWindow(" -= Pyton Win10 edition 2025 by @Quriositer =- ");

   
    glEnable(GL_LINE_SMOOTH);
    glHint(GL_LINE_SMOOTH_HINT, GL_NICEST);

  
    glEnable(GL_POLYGON_SMOOTH);
    glHint(GL_POLYGON_SMOOTH_HINT, GL_NICEST);

  
    isCongratShowing = false;
    gameWon = false;
    textAlpha = 1.0f;
    hueShift = 0.0f;

    gluOrtho2D(0, w, 0, h); 
    glutSpecialFunc(MyKeyboard); 
    glutDisplayFunc(display); 
    glutTimerFunc(current_speed, timer, 0); 

    glutMainLoop(); 
    return 0;
}
