#include "glwidget.h"
#include <QOpenGLShader>
#include <QPainter>

static const float vertices[] = {
    // x,y,z         r,g,b
    -1,-1,-1,  1,0,0,
     1,-1,-1,  0,1,0,
     1, 1,-1,  0,0,1,
    -1, 1,-1,  1,1,0,
    -1,-1, 1,  1,0,1,
     1,-1, 1,  0,1,1,
     1, 1, 1,  1,1,1,
    -1, 1, 1,  0,0,0,
};

static const GLubyte indices[] = {
    0,1,2, 2,3,0,
    4,5,6, 6,7,4,
    0,4,7, 7,3,0,
    1,5,6, 6,2,1,
    0,1,5, 5,4,0,
    3,2,6, 6,7,3
};

GLWidget::GLWidget(QWidget *parent) : QOpenGLWidget(parent) { }

void GLWidget::initializeGL()
{
    initializeOpenGLFunctions();
    glEnable(GL_DEPTH_TEST);

    m_program = new QOpenGLShaderProgram(this);
    m_program->addShaderFromSourceCode(QOpenGLShader::Vertex,
        "uniform mat4 mvp;\n"
        "attribute vec4 vPos;\n"
        "attribute vec3 vCol;\n"
        "varying vec3 fCol;\n"
        "void main() {\n"
        "   gl_Position = mvp * vPos;\n"
        "   fCol = vCol;\n"
        "}");
    m_program->addShaderFromSourceCode(QOpenGLShader::Fragment,
        "varying mediump vec3 fCol;\n"
        "void main() {\n"
        "   gl_FragColor = vec4(fCol,1.0);\n"
        "}");
    m_program->link();
    m_vertexAttr  = m_program->attributeLocation("vPos");
    m_colorAttr   = m_program->attributeLocation("vCol");
    m_matrixUniform=m_program->uniformLocation("mvp");

    glVertexAttribPointer(m_vertexAttr, 3, GL_FLOAT, GL_FALSE, 6*4, vertices);
    glVertexAttribPointer(m_colorAttr,  3, GL_FLOAT, GL_FALSE, 6*4, vertices+3);
    glEnableVertexAttribArray(m_vertexAttr);
    glEnableVertexAttribArray(m_colorAttr);

    m_timer.start();
}

void GLWidget::resizeGL(int w, int h)
{
    m_proj.setToIdentity();
    m_proj.perspective(45.f, float(w)/h, 0.1f, 100.f);
}

void GLWidget::paintGL()
{
    glClearColor(0.1f,0.15f,0.2f,1);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);

    // atualiza ângulo
    float dt = m_timer.restart() / 1000.f;
    m_angle += m_speed * dt;
    m_model.setToIdentity();
    m_model.rotate(m_angle, 0,1,0);
    m_model.rotate(m_angle*0.7f, 1,0,0);

    QMatrix4x4 mvp = m_proj * m_view * m_model;
    m_program->bind();
    m_program->setUniformValue(m_matrixUniform, mvp);

    glDrawElements(GL_TRIANGLES, 36, GL_UNSIGNED_BYTE, indices);
    m_program->release();

    // HUD 2-D com FPS
    QPainter p(this);
    p.setPen(Qt::white);
    p.drawText(10,20, QString("FPS: %1").arg(int(1.f/dt)));
}

void GLWidget::mousePressEvent(QMouseEvent *)
{
    m_speed = m_speed == 30.f ? 90.f : 30.f;
    update();
}
