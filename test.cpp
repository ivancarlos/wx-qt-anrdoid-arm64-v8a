#include <wx/timer.h>
#include <wx/wx.h>

class MyApp : public wxApp {
public:
  virtual bool OnInit() override {
    // ADIA a criação da janela para o loop Qt estar 100% inicializado
    wxTimer::StartOnce(900, [this]() {
      wxFrame *f = new wxFrame(NULL, wxID_ANY, "WX/Qt Android Test",
                               wxDefaultPosition, wxSize(400, 300));
      new wxButton(f, wxID_ANY, "OK", wxPoint(50, 50));
      f->Show();
    });

    return true;
  }
};

wxIMPLEMENT_APP(MyApp);
