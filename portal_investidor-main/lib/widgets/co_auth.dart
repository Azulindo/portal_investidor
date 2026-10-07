import 'package:flutter/material.dart';

import '../theme/co_colors.dart';
import '../theme/co_tokens.dart';

/// Peças comuns aos ecrãs de autenticação (entrar, criar conta, recuperar
/// acesso, reenviar confirmação).
///
/// Antes a decoração dos campos estava escrita à mão em cada ecrã, com 30
/// linhas por campo. Assim os quatro ecrãs ficam iguais de graça, e mudar o
/// aspeto é mudar num sítio.

/// Moldura dos ecrãs de autenticação: fundo navy, logo, etiqueta, título,
/// subtítulo, o formulário e os links do fim.
class CoAuthScaffold extends StatelessWidget {
  const CoAuthScaffold({
    super.key,
    required this.titulo,
    required this.filhos,
    this.subtitulo,
    this.rodape = const [],
    this.mostrarVoltar = false,
  });

  final String titulo;
  final String? subtitulo;
  final List<Widget> filhos;
  final List<Widget> rodape;
  final bool mostrarVoltar;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: COColors.brand900,
      resizeToAvoidBottomInset: true,
      appBar: mostrarVoltar
          ? AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              toolbarHeight: COTokens.headerHeight,
              iconTheme: const IconThemeData(color: COColors.brand300),
            )
          : null,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: COTokens.space6,
              vertical: COTokens.space8,
            ),
            child: ConstrainedBox(
              // Em tablet e em web o formulário não deve esticar até à borda.
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Image.asset(
                    'assets/images/logo.png',
                    height: 96,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(height: COTokens.space8),
                  Text('ÁREA RESERVADA',
                      style: COText.overline, textAlign: TextAlign.center),
                  const SizedBox(height: COTokens.space2),
                  Text(titulo, style: COText.h1, textAlign: TextAlign.center),
                  if (subtitulo != null) ...[
                    const SizedBox(height: COTokens.space2),
                    Text(subtitulo!,
                        style: COText.small, textAlign: TextAlign.center),
                  ],
                  const SizedBox(height: COTokens.space8),
                  ...filhos,
                  if (rodape.isNotEmpty) ...[
                    const SizedBox(height: COTokens.space6),
                    ...rodape,
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Campo de texto dos formulários de autenticação.
///
/// É um TextFormField (e não um TextField) para o erro aparecer debaixo do
/// campo e o Form poder validar tudo de uma vez.
class CoCampo extends StatefulWidget {
  const CoCampo({
    super.key,
    required this.controller,
    required this.etiqueta,
    this.pista,
    this.validador,
    this.tipo = TextInputType.text,
    this.password = false,
    this.autofill = const [],
    this.maiusculas = TextCapitalization.none,
    this.maxLength,
    this.proximo = TextInputAction.next,
    this.aoSubmeter,
  });

  final TextEditingController controller;
  final String etiqueta;

  /// Exemplo do que se espera no campo ("ex. joao.silva@email.com").
  final String? pista;
  final String? Function(String?)? validador;
  final TextInputType tipo;
  final bool password;
  final List<String> autofill;
  final TextCapitalization maiusculas;
  final int? maxLength;
  final TextInputAction proximo;
  final void Function(String)? aoSubmeter;

  @override
  State<CoCampo> createState() => _CoCampoState();
}

class _CoCampoState extends State<CoCampo> {
  bool _escondida = true;

  OutlineInputBorder _borda(Color cor, [double espessura = COTokens.borderWidth]) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(COTokens.radiusSm),
      borderSide: BorderSide(color: cor, width: espessura),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: COTokens.space4),
      child: TextFormField(
        controller: widget.controller,
        keyboardType: widget.tipo,
        obscureText: widget.password && _escondida,
        autofillHints: widget.autofill,
        textCapitalization: widget.maiusculas,
        maxLength: widget.maxLength,
        textInputAction: widget.proximo,
        onFieldSubmitted: widget.aoSubmeter,
        validator: widget.validador,
        style: COText.small.copyWith(
          color: COColors.white,
          fontWeight: COTokens.fwRegular,
        ),
        decoration: InputDecoration(
          labelText: widget.etiqueta,
          hintText: widget.pista,
          counterText: '',
          labelStyle: COText.small,
          hintStyle: COText.caption,
          errorStyle: COText.caption.copyWith(color: const Color(0xFFFFB4A9)),
          filled: true,
          fillColor: COColors.brand700,
          enabledBorder: _borda(COColors.brand700),
          focusedBorder: _borda(COColors.brand300, 1.5),
          errorBorder: _borda(const Color(0xFFFFB4A9)),
          focusedErrorBorder: _borda(const Color(0xFFFFB4A9), 1.5),
          suffixIcon: widget.password
              ? IconButton(
                  icon: Icon(
                    _escondida
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    color: COColors.brand300,
                    size: 20,
                  ),
                  onPressed: () => setState(() => _escondida = !_escondida),
                )
              : null,
        ),
      ),
    );
  }
}

/// Botão principal: branco, cantos vivos, texto em maiúsculas.
class CoBotao extends StatelessWidget {
  const CoBotao({
    super.key,
    required this.texto,
    required this.aoCarregar,
    this.aCarregar = false,
  });

  final String texto;
  final VoidCallback? aoCarregar;

  /// Mostra um indicador em vez do texto e desliga o botão.
  final bool aCarregar;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: aCarregar ? null : aoCarregar,
      style: ElevatedButton.styleFrom(
        backgroundColor: COColors.white,
        disabledBackgroundColor: COColors.brand300,
        padding: const EdgeInsets.symmetric(vertical: 20),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(COTokens.radiusNone)),
        ),
        elevation: 0,
      ),
      child: aCarregar
          ? const SizedBox(
              height: 18,
              width: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: COColors.brand900,
              ),
            )
          : Text(
              texto.toUpperCase(),
              style: COText.small.copyWith(
                color: COColors.brand900,
                fontWeight: COTokens.fwBold,
                letterSpacing: 2,
              ),
            ),
    );
  }
}

/// Linha do tipo "Já tem conta? Inicie sessão", com a segunda parte clicável.
class CoLinkAuth extends StatelessWidget {
  const CoLinkAuth({
    super.key,
    required this.pergunta,
    required this.acao,
    required this.aoCarregar,
  });

  final String pergunta;
  final String acao;
  final VoidCallback aoCarregar;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: COTokens.space2),
      child: Center(
        child: Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(pergunta, style: COText.small),
            const SizedBox(width: 6),
            InkWell(
              onTap: aoCarregar,
              child: Container(
                // Alvo de toque com altura decente, sem afastar o texto.
                padding: const EdgeInsets.only(top: 6, bottom: 4),
                // Risco por baixo em vez de TextDecoration.underline: o
                // sublinhado do Flutter passa por cima dos descendentes, e
                // em "Recuperar acesso" e "Criar conta" o traço cortava o
                // "p" e o "ç" a meio.
                decoration: const BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: COColors.brand300),
                  ),
                ),
                child: Text(
                  acao,
                  style: COText.small.copyWith(
                    color: COColors.white,
                    fontWeight: COTokens.fwMedium,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Aviso dentro do formulário (erro do servidor, ou nota de sucesso).
class CoAviso extends StatelessWidget {
  const CoAviso({super.key, required this.texto, this.erro = true});

  final String texto;
  final bool erro;

  @override
  Widget build(BuildContext context) {
    final cor = erro ? const Color(0xFFFFB4A9) : COColors.brand300;
    return Container(
      margin: const EdgeInsets.only(bottom: COTokens.space4),
      padding: const EdgeInsets.all(COTokens.space4),
      decoration: BoxDecoration(
        color: COColors.brand700,
        borderRadius: BorderRadius.circular(COTokens.radiusSm),
        border: Border(left: BorderSide(color: cor, width: 3)),
      ),
      child: Text(texto, style: COText.small.copyWith(color: COColors.white)),
    );
  }
}
