#include <QApplication>
#include <QWidget>
#include <QPushButton>
#include <QLabel>
#include <QVBoxLayout>
#include <QHBoxLayout>
#include <QMessageBox>
#include <QFont>
#include <QTimer>
#include <QDateTime>

class SimpleApp : public QWidget
{
    Q_OBJECT

public:
    SimpleApp(QWidget *parent = nullptr) : QWidget(parent), counter(0)
    {
        setWindowTitle("WxApp Test");
        resize(400, 600);
        
        // Layout principal
        QVBoxLayout *mainLayout = new QVBoxLayout(this);
        mainLayout->setSpacing(20);
        mainLayout->setContentsMargins(20, 40, 20, 20);
        
        // Título
        QLabel *title = new QLabel("🎯 Teste WxWidgets + Qt");
        QFont titleFont = title->font();
        titleFont.setPointSize(20);
        titleFont.setBold(true);
        title->setFont(titleFont);
        title->setAlignment(Qt::AlignCenter);
        title->setStyleSheet("color: #2196F3; padding: 10px;");
        mainLayout->addWidget(title);
        
        // Label do contador
        counterLabel = new QLabel("Cliques: 0");
        QFont counterFont = counterLabel->font();
        counterFont.setPointSize(32);
        counterFont.setBold(true);
        counterLabel->setFont(counterFont);
        counterLabel->setAlignment(Qt::AlignCenter);
        counterLabel->setStyleSheet(
            "background-color: #E3F2FD; "
            "color: #1565C0; "
            "border-radius: 15px; "
            "padding: 30px; "
            "margin: 10px;"
        );
        mainLayout->addWidget(counterLabel);
        
        // Label de hora
        timeLabel = new QLabel(QDateTime::currentDateTime().toString("HH:mm:ss"));
        timeLabel->setAlignment(Qt::AlignCenter);
        QFont timeFont = timeLabel->font();
        timeFont.setPointSize(16);
        timeLabel->setFont(timeFont);
        timeLabel->setStyleSheet("color: #666; padding: 10px;");
        mainLayout->addWidget(timeLabel);
        
        // Timer para atualizar hora
        QTimer *timer = new QTimer(this);
        connect(timer, &QTimer::timeout, this, &SimpleApp::updateTime);
        timer->start(1000);
        
        // Botões coloridos
        QPushButton *btnIncrement = createButton("➕ Incrementar", "#4CAF50");
        QPushButton *btnDecrement = createButton("➖ Decrementar", "#FF9800");
        QPushButton *btnReset = createButton("🔄 Resetar", "#F44336");
        QPushButton *btnInfo = createButton("ℹ️ Info", "#9C27B0");
        
        mainLayout->addWidget(btnIncrement);
        mainLayout->addWidget(btnDecrement);
        mainLayout->addWidget(btnReset);
        mainLayout->addWidget(btnInfo);
        
        // Spacer para empurrar tudo para cima
        mainLayout->addStretch();
        
        // Rodapé
        QLabel *footer = new QLabel("wxWidgets 3.2.4 + Qt 5.15 • Android arm64");
        footer->setAlignment(Qt::AlignCenter);
        footer->setStyleSheet("color: #999; font-size: 12px; padding: 10px;");
        mainLayout->addWidget(footer);
        
        // Conectar sinais
        connect(btnIncrement, &QPushButton::clicked, this, &SimpleApp::increment);
        connect(btnDecrement, &QPushButton::clicked, this, &SimpleApp::decrement);
        connect(btnReset, &QPushButton::clicked, this, &SimpleApp::reset);
        connect(btnInfo, &QPushButton::clicked, this, &SimpleApp::showInfo);
        
        setLayout(mainLayout);
        
        // Estilo geral
        setStyleSheet("QWidget { background-color: #FAFAFA; }");
    }

private slots:
    void increment()
    {
        counter++;
        updateCounter();
    }
    
    void decrement()
    {
        counter--;
        updateCounter();
    }
    
    void reset()
    {
        counter = 0;
        updateCounter();
        QMessageBox::information(this, "Reset", "Contador resetado! 🔄");
    }
    
    void showInfo()
    {
        QMessageBox::information(
            this, 
            "Informações do App",
            "📱 <b>WxApp Test</b><br><br>"
            "🔧 <b>Stack:</b><br>"
            "• wxWidgets 3.2.4<br>"
            "• Qt 5.15.2<br>"
            "• Android NDK r21e<br><br>"
            "🎯 <b>Arquitetura:</b> arm64-v8a<br><br>"
            "✨ App compilado com sucesso!"
        );
    }
    
    void updateTime()
    {
        timeLabel->setText(QDateTime::currentDateTime().toString("🕐 HH:mm:ss"));
    }

private:
    QPushButton* createButton(const QString &text, const QString &color)
    {
        QPushButton *btn = new QPushButton(text);
        QFont btnFont = btn->font();
        btnFont.setPointSize(16);
        btnFont.setBold(true);
        btn->setFont(btnFont);
        btn->setMinimumHeight(70);
        btn->setStyleSheet(QString(
            "QPushButton {"
            "  background-color: %1;"
            "  color: white;"
            "  border: none;"
            "  border-radius: 12px;"
            "  padding: 15px;"
            "}"
            "QPushButton:pressed {"
            "  background-color: %2;"
            "}"
        ).arg(color).arg(darkenColor(color)));
        return btn;
    }
    
    QString darkenColor(const QString &color)
    {
        // Escurece a cor em 20% para o efeito pressed
        QColor c(color);
        return c.darker(120).name();
    }
    
    void updateCounter()
    {
        counterLabel->setText(QString("Cliques: %1").arg(counter));
        
        // Muda cor baseado no valor
        QString bgColor, textColor;
        if (counter > 0) {
            bgColor = "#C8E6C9"; // Verde claro
            textColor = "#2E7D32"; // Verde escuro
        } else if (counter < 0) {
            bgColor = "#FFCDD2"; // Vermelho claro
            textColor = "#C62828"; // Vermelho escuro
        } else {
            bgColor = "#E3F2FD"; // Azul claro
            textColor = "#1565C0"; // Azul escuro
        }
        
        counterLabel->setStyleSheet(QString(
            "background-color: %1; "
            "color: %2; "
            "border-radius: 15px; "
            "padding: 30px; "
            "margin: 10px;"
        ).arg(bgColor).arg(textColor));
    }

    QLabel *counterLabel;
    QLabel *timeLabel;
    int counter;
};

int main(int argc, char *argv[])
{
    QApplication app(argc, argv);
    
    SimpleApp window;
    window.show();
    
    return app.exec();
}

#include "qt_stub.moc"
