import 'package:fluffychat/config/app_config.dart';
import 'package:fluffychat/config/themes.dart';
import 'package:fluffychat/l10n/l10n.dart';
import 'package:fluffychat/pages/chat_list/navi_rail_item.dart';
import 'package:fluffychat/pages/chat_list/start_chat_fab.dart';
import 'package:fluffychat/utils/matrix_sdk_extensions/matrix_locals.dart';
import 'package:fluffychat/utils/stream_extension.dart';
import 'package:fluffychat/widgets/adaptive_dialogs/show_ok_cancel_alert_dialog.dart';
import 'package:fluffychat/widgets/avatar.dart';
import 'package:fluffychat/widgets/future_loading_dialog.dart';
import 'package:fluffychat/widgets/matrix.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:matrix/matrix.dart';

class SpacesNavigationRail extends StatelessWidget {
  final String? activeSpaceId;
  final void Function() onGoToChats;
  final void Function(String) onGoToSpaceId;

  const SpacesNavigationRail({
    required this.activeSpaceId,
    required this.onGoToChats,
    required this.onGoToSpaceId,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final client = Matrix.of(context).client;
    return Material(
      child: SafeArea(
        child: StreamBuilder(
          key: ValueKey(client.userID.toString()),
          stream: client.onSync.stream
              .where((s) => s.hasRoomUpdate)
              .rateLimit(const Duration(seconds: 1)),
          builder: (context, _) {
            final allSpaces = client.rooms
                .where((room) => room.isSpace)
                .toList();

            return SizedBox(
              width: FluffyThemes.isColumnMode(context)
                  ? FluffyThemes.navRailWidth
                  : FluffyThemes.navRailWidth * 0.75,
              child: Column(
                children: [
                  Expanded(
                    child: ListView.builder(
                      scrollDirection: Axis.vertical,
                      itemCount: allSpaces.length + 2,
                      itemBuilder: (context, i) {
                        if (i == 0) {
                          return NaviRailItem(
                            isSelected: activeSpaceId == null,
                            onTap: onGoToChats,
                            icon: const Padding(
                              padding: EdgeInsets.all(10.0),
                              child: Icon(Icons.forum_outlined),
                            ),
                            selectedIcon: const Padding(
                              padding: EdgeInsets.all(10.0),
                              child: Icon(Icons.forum),
                            ),
                            toolTip: L10n.of(context).chats,
                            unreadBadgeFilter: (room) => true,
                          );
                        }
                        i--;
                        // wevolu: "New space" button hidden — space creation not supported
                        if (i == allSpaces.length) {
                          return const SizedBox.shrink();
                        }
                        final space = allSpaces[i];
                        final displayname = allSpaces[i]
                            .getLocalizedDisplayname(
                              MatrixLocals(L10n.of(context)),
                            );
                        final spaceChildrenIds = space.spaceChildren
                            .map((c) => c.roomId)
                            .toSet();
                        return NaviRailItem(
                          toolTip: displayname,
                          isSelected: activeSpaceId == space.id,
                          onTap: () => onGoToSpaceId(allSpaces[i].id),
                          unreadBadgeFilter: (room) =>
                              spaceChildrenIds.contains(room.id),
                          icon: Avatar(
                            mxContent: allSpaces[i].avatar,
                            name: displayname,
                            shapeBorder: RoundedSuperellipseBorder(
                              side: BorderSide(
                                width: 1,
                                color: Theme.of(context).dividerColor,
                              ),
                              borderRadius: BorderRadius.circular(
                                AppConfig.spaceBorderRadius,
                              ),
                            ),
                            borderRadius: BorderRadius.circular(
                              AppConfig.spaceBorderRadius,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  // wevolu: "New chat" FAB hidden in desktop nav rail — direct room creation not supported
                  // if (FluffyThemes.isColumnMode(context))
                  //   Padding(
                  //     padding: const EdgeInsets.all(12.0),
                  //     child: StartChatFab(),
                  //   ),
                  NaviRailItem(
                    isSelected: false,
                    onTap: () async {
                      final matrix = Matrix.of(context);
                      final cryptoConnected = matrix
                              .client.encryption?.crossSigning.enabled ==
                          true;
                      if (await showOkCancelAlertDialog(
                            useRootNavigator: false,
                            context: context,
                            title: L10n.of(context).areYouSureYouWantToLogout,
                            message: L10n.of(context).noBackupWarning,
                            isDestructive: !cryptoConnected,
                            okLabel: L10n.of(context).logout,
                            cancelLabel: L10n.of(context).cancel,
                          ) ==
                          OkCancelResult.cancel) {
                        return;
                      }
                      await showFutureLoadingDialog(
                        context: context,
                        future: () => matrix.client.logout(),
                      );
                    },
                    icon: const Padding(
                      padding: EdgeInsets.all(10.0),
                      child: Icon(Icons.logout_outlined),
                    ),
                    selectedIcon: const Padding(
                      padding: EdgeInsets.all(10.0),
                      child: Icon(Icons.logout),
                    ),
                    toolTip: L10n.of(context).logout,
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
