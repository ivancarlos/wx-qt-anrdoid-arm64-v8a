#include <wx/wx.h>
#include <wx/dialog.h>

class MyApp : public wxApp
{
public:
    virtual bool OnInit() override;
};

wxIMPLEMENT_APP_NO_MAIN(MyApp);  // No Android, o Qt chama main()

// -----------------------------
// Cria o diálogo
// -----------------------------
class SimpleDialog : public wxDialog
{
public:
    SimpleDialog(wxWindow* parent)
        : wxDialog(parent, wxID_ANY, "Dialogo Simples",
                   wxDefaultPosition, wxDefaultSize,
                   wxDEFAULT_DIALOG_STYLE | wxRESIZE_BORDER)
    {
        wxBoxSizer* sizer = new wxBoxSizer(wxVERTICAL);

        wxStaticText* label =
            new wxStaticText(this, wxID_ANY,
                             "Olá, Ivan!\nEste é um diálogo wxWidgets rodando no Android.");

        wxButton* btnOK = new wxButton(this, wxID_OK, "OK");

        sizer->Add(label, 0, wxALL | wxALIGN_CENTER, 20);
        sizer->Add(btnOK, 0, wxALL | wxALIGN_CENTER, 20);

        SetSizerAndFit(sizer);
    }
};

// -----------------------------
// OnInit
// -----------------------------
bool MyApp::OnInit()
{
    SimpleDialog dlg(nullptr);
    dlg.ShowModal();
    return false; // encerra o app após fechar o diálogo
}

