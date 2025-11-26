#include <wx/wx.h>

class MyApp : public wxApp
{
public:
    bool OnInit() override
    {
        // Aqui a janela do Android já existe!
        wxFrame* f = new wxFrame(nullptr, wxID_ANY,
                                 "wxWidgets rodando em Android (Qt backend)",
                                 wxDefaultPosition, wxSize(400, 300));

        new wxButton(f, wxID_ANY, "Clique aqui",
                     wxPoint(20,20), wxSize(200,80));

        f->Show();

        return true;
    }

    int OnExit() override
    {
        return wxApp::OnExit();
    }
};

wxIMPLEMENT_APP_NO_MAIN(MyApp);

