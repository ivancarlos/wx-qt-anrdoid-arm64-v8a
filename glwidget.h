#pragma once
#include <QOpenGLWidget>
#include <QOpenGLFunctions>
#include <QOpenGLShaderProgram>
#include <QMatrix4x4>
#include <QElapsedTimer>

class GLWidget : public QOpenGLWidget, protected QOpenGLFunctions
{
    Q_OBJECT
public:
    explicit GLWidget(QWidget *parent = nullptr);
protected:
    void initializeGL() override;
    void resizeGL(int w, int h) override;
    void paintGL() override;
    void mousePressEvent(QMouseEvent *) override;
private:
    QOpenGLShaderProgram *m_program = nullptr;
    QMatrix4x4 m_proj, m_view, m_model;
    QElapsedTimer m_timer;
    float m_angle = 0;
    float m_speed = 30.f; // graus/s
    int m_vertexAttr = 0;
    int m_colorAttr  = 0;
    int m_matrixUniform = 0;
};
