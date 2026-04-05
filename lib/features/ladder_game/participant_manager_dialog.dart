import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/neon_theme.dart';
import 'ladder_game_view_model.dart';
import '../../core/sound_manager.dart';
import '../../core/widgets/neon_3d_button.dart';

class ParticipantManagerDialog extends StatefulWidget {
  const ParticipantManagerDialog({super.key});

  @override
  State<ParticipantManagerDialog> createState() => _ParticipantManagerDialogState();
}

class _ParticipantManagerDialogState extends State<ParticipantManagerDialog> {
  final List<TextEditingController> _nameControllers = [];
  final List<FocusNode> _focusNodes = [];
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    final viewModel = context.read<LadderGameViewModel>();
    _rebuildControllers(viewModel);
  }

  void _rebuildControllers(LadderGameViewModel viewModel) {
    for (final c in _nameControllers) c.dispose();
    for (final f in _focusNodes) f.dispose();
    _nameControllers.clear();
    _focusNodes.clear();

    for (int i = 0; i < viewModel.playerCount; i++) {
      // 안전을 위해 currentParticipants 범위를 확인합니다.
      if (i >= viewModel.currentParticipants.length) break;
      
      final p = viewModel.currentParticipants[i];
      _nameControllers.add(TextEditingController(text: p.customName ?? p.animalType));
      final fn = FocusNode();
      fn.addListener(() {
        if (fn.hasFocus && _scrollController.hasClients) {
          Future.delayed(const Duration(milliseconds: 350), () {
            final idx = _focusNodes.indexOf(fn);
            final targetOffset = idx * 64.0;
            _scrollController.animateTo(
              targetOffset.clamp(0.0, _scrollController.position.maxScrollExtent),
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
            );
          });
        }
      });
      _focusNodes.add(fn);
    }
  }

  @override
  void dispose() {
    for (final c in _nameControllers) c.dispose();
    for (final f in _focusNodes) f.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _saveAndClose() {
    final viewModel = context.read<LadderGameViewModel>();
    for (int i = 0; i < _nameControllers.length; i++) {
      viewModel.updateParticipantName(i, _nameControllers[i].text);
    }
    SoundManager().playTick();
    viewModel.setPlayerCount(viewModel.playerCount);
    Navigator.pop(context);
  }

  void _showAnimalPicker(int index) {
    final viewModel = context.read<LadderGameViewModel>();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(32),
          side: const BorderSide(color: NeonColors.primary, width: 2),
        ),
        title: const Text('동물 선택', style: TextStyle(color: NeonColors.primary, fontWeight: FontWeight.bold)),
        content: SizedBox(
          width: double.maxFinite,
          height: 280,
          child: GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 5,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
            ),
            itemCount: viewModel.allAvailableParticipants.length,
            itemBuilder: (_, i) {
              final animal = viewModel.allAvailableParticipants[i];
              return GestureDetector(
                onTap: () {
                  SoundManager().playTick();
                  viewModel.changeParticipantAnimal(index, animal);
                  setState(() {
                    _nameControllers[index].text = animal.animalType;
                  });
                  Navigator.pop(ctx);
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF9F7F2),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: NeonColors.textSub.withOpacity(0.1)),
                  ),
                  child: Center(
                    child: Text(animal.emoji, style: const TextStyle(fontSize: 24)),
                  ),
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('취소', style: TextStyle(color: NeonColors.textSub)),
          ),
        ],
      ),
    );
  }

  void _showSaveDialog() async {
    final viewModel = context.read<LadderGameViewModel>();
    final lists = await viewModel.getSavedLists();
    if (lists.length >= 5) {
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28), side: const BorderSide(color: Color(0xFFBE2D06), width: 2)),
          title: Row(
            children: [
              const Icon(Icons.warning_amber_rounded, color: Color(0xFFBE2D06)),
              const SizedBox(width: 8),
              Text('저장 용량 초과', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w900, color: const Color(0xFFBE2D06))),
            ],
          ),
          content: Text('명단은 최대 5개까지만 저장할 수 있습니다.\n기존 명단을 삭제한 후 다시 시도해 주세요.', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, color: NeonColors.textMain)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('확인', style: GoogleFonts.plusJakartaSans(color: NeonColors.textSub, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );
      return;
    }

    for (int i = 0; i < _nameControllers.length; i++) {
      viewModel.updateParticipantName(i, _nameControllers[i].text);
    }
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (ctx) {
        String presetName = '';
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            decoration: NeonTheme.getCardDecoration(radius: 28),
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    const Icon(Icons.drive_file_rename_outline, color: NeonColors.primary, size: 24),
                    const SizedBox(width: 12),
                    Text(
                      '명단 저장',
                      style: GoogleFonts.plusJakartaSans(
                        color: NeonColors.primary,
                        fontWeight: FontWeight.w900,
                        fontSize: 20,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                TextField(
                  style: GoogleFonts.plusJakartaSans(color: NeonColors.textMain, fontWeight: FontWeight.w600),
                  decoration: InputDecoration(
                    hintText: '저장할 이름을 입력하세요',
                    hintStyle: GoogleFonts.plusJakartaSans(color: NeonColors.textSub.withOpacity(0.5)),
                    filled: true,
                    fillColor: Colors.white,
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: NeonColors.stroke, width: 2),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: NeonColors.primary, width: 2),
                    ),
                  ),
                  autofocus: true,
                  onChanged: (val) => presetName = val,
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: Text('취소', style: GoogleFonts.plusJakartaSans(color: NeonColors.textSub, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Neon3DButton(
                        size: 48,
                        isCircle: false,
                        onPressed: () async {
                          if (presetName.trim().isNotEmpty) {
                            final messenger = ScaffoldMessenger.of(context);
                            final navCtx = Navigator.of(ctx);
                            final navThis = Navigator.of(context);
                            await viewModel.saveCurrentParticipants(presetName.trim());
                            navCtx.pop();
                            navThis.pop();
                            messenger.showSnackBar(SnackBar(
                              content: Text("'$presetName' 명단이 저장되었습니다."),
                              backgroundColor: NeonColors.primary,
                            ));
                          }
                        },
                        child: const Text('저장', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showLoadDialog() async {
    final viewModel = context.read<LadderGameViewModel>();
    final lists = await viewModel.getSavedLists();
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (ctx) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            decoration: NeonTheme.getCardDecoration(radius: 28, bg: const Color(0xFFF5F4EB)),
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(ctx),
                      icon: const Icon(Icons.arrow_back_ios_new, color: NeonColors.primary, size: 18),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '명단 불러오기',
                      style: GoogleFonts.plusJakartaSans(
                        color: NeonColors.primary,
                        fontWeight: FontWeight.w900,
                        fontSize: 20,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: NeonColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${lists.length}/5',
                        style: GoogleFonts.plusJakartaSans(color: NeonColors.primary, fontWeight: FontWeight.w900, fontSize: 12),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.maxFinite,
                  height: 350,
                  child: lists.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.inventory_2_outlined, size: 48, color: NeonColors.textSub.withValues(alpha: 0.3)),
                              const SizedBox(height: 16),
                              Text('저장된 명단이 없습니다.', style: GoogleFonts.plusJakartaSans(color: NeonColors.textSub, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        )
                      : ListView.separated(
                          itemCount: lists.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 12),
                          itemBuilder: (_, i) {
                            return InkWell(
                              onTap: () async {
                                final nav = Navigator.of(ctx);
                                await viewModel.loadParticipantList(lists[i]);
                                nav.pop();
                                if (mounted) setState(() => _rebuildControllers(viewModel));
                              },
                              borderRadius: BorderRadius.circular(20),
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: NeonColors.stroke, width: 2),
                                  boxShadow: [
                                    BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4, offset: const Offset(0, 2)),
                                  ],
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: NeonColors.pointGreen.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                      child: const Icon(Icons.person_pin_outlined, color: NeonColors.pointGreen, size: 24),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(lists[i], style: GoogleFonts.plusJakartaSans(color: NeonColors.textMain, fontSize: 16, fontWeight: FontWeight.w900)),
                                          Text('명단 등록됨', style: GoogleFonts.plusJakartaSans(color: NeonColors.textSub, fontSize: 12, fontWeight: FontWeight.w600)),
                                        ],
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline, color: Color(0xFFBE2D06), size: 24),
                                      onPressed: () async {
                                        final nav = Navigator.of(ctx);
                                        await viewModel.deleteParticipantList(lists[i]);
                                        nav.pop();
                                        _showLoadDialog(); // Re-open
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<LadderGameViewModel>();

    if (_nameControllers.length != viewModel.playerCount) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _rebuildControllers(viewModel));
      });
    }

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Container(
        decoration: BoxDecoration(
          color: NeonColors.background,
          borderRadius: BorderRadius.circular(32),
          border: Border.all(color: NeonColors.stroke, width: 2),
          boxShadow: [
            BoxShadow(
              color: NeonColors.shadow.withOpacity(0.1),
              blurRadius: 30,
              offset: const Offset(0, 15),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
              child: Row(
                children: [
                  IconButton(
                    onPressed: _saveAndClose,
                    icon: const Icon(Icons.arrow_back_ios_new, size: 22, color: NeonColors.primary),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      '명단 관리',
                      style: GoogleFonts.plusJakartaSans(
                        color: NeonColors.primary,
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Neon3DButton(
                    size: 38,
                    onPressed: () {
                      if (viewModel.playerCount > 2) {
                        viewModel.setPlayerCount(viewModel.playerCount - 1);
                      }
                    },
                    child: const Icon(Icons.remove, color: Colors.white, size: 18),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    width: 28,
                    alignment: Alignment.center,
                    child: Text(
                      '${viewModel.playerCount}',
                      style: GoogleFonts.plusJakartaSans(
                        color: NeonColors.primary, 
                        fontWeight: FontWeight.w900, 
                        fontSize: 18,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Neon3DButton(
                    size: 38,
                    onPressed: () {
                      if (viewModel.playerCount < 20) {
                        viewModel.setPlayerCount(viewModel.playerCount + 1);
                      }
                    },
                    child: const Icon(Icons.add, color: Colors.white, size: 18),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: Color(0xFFE5E0D5)),
            Flexible(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shrinkWrap: true,
                itemCount: viewModel.playerCount,
                itemBuilder: (_, i) {
                  // 인덱스 초과 에러 방지를 위한 2중 안전 장치
                  if (i >= _nameControllers.length || i >= viewModel.currentParticipants.length) {
                    return const SizedBox();
                  }
                  final p = viewModel.currentParticipants[i];
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: () {
                            SoundManager().playTick();
                            _showAnimalPicker(i);
                          },
                          child: Container(
                            width: 48, height: 48,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: NeonColors.stroke.withOpacity(0.1)),
                              boxShadow: [
                                BoxShadow(
                                  color: NeonColors.shadow.withOpacity(0.02),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Center(
                              child: Text(p.emoji, style: const TextStyle(fontSize: 24)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _nameControllers[i],
                            focusNode: _focusNodes[i],
                            style: GoogleFonts.plusJakartaSans(color: NeonColors.textMain, fontSize: 15, fontWeight: FontWeight.w600),
                            decoration: InputDecoration(
                              hintText: '참가자 이름',
                              hintStyle: TextStyle(color: NeonColors.textSub.withOpacity(0.5)),
                              filled: true,
                              fillColor: Colors.white,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: const BorderSide(color: NeonColors.stroke, width: 1),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: const BorderSide(color: NeonColors.stroke, width: 2),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: const BorderSide(color: NeonColors.primary, width: 2),
                              ),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            ),
                            onChanged: (val) => viewModel.updateParticipantName(i, val),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            const Divider(height: 1, color: Color(0xFFE5E0D5)),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Expanded(
                    child: Neon3DButton(
                      size: 56,
                      isCircle: false,
                      baseColor: Colors.white,
                      onPressed: () {
                        SoundManager().playTick();
                        _showLoadDialog();
                      },
                      child: Text(
                        '불러오기',
                        style: GoogleFonts.plusJakartaSans(
                          color: NeonColors.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Neon3DButton(
                      size: 56,
                      isCircle: false,
                      baseColor: NeonColors.primary,
                      onPressed: () {
                        SoundManager().playTick();
                        _showSaveDialog();
                      },
                      child: Text(
                        '명단 저장',
                        style: GoogleFonts.plusJakartaSans(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
