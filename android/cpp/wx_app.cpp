#include "wx_app.h"

bool MyApp::OnInit()
{
    wxFrame* f = new wxFrame(nullptr, wxID_ANY,
                             "wxWidgets rodando em Android (Qt backend)",
                             wxDefaultPosition, wxSize(400, 300));

    new wxButton(f, wxID_ANY, "Clique aqui",
                 wxPoint(20,20), wxSize(200,80));

    f->Show();
    return true;
}

int MyApp::OnExit()
{
    return wxApp::OnExit();
}

// IMPORTANTE
wxIMPLEMENT_APP_NO_MAIN(MyApp);

