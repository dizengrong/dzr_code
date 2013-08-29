####################################################################
## @author QingliangCn <qing.liang.cn@gmail.com>
## @datetime 2010-05-30
## @description beam文件被放在ebin下或者ebin子目录下，所以启动时要
##				注意-pa参数是否设置正确
##
####################################################################

##指定当前项目在svn仓库中的名字
APP_NAME := world
SRC_DIRS := src/*.erl src/hook/*.erl src/mod/*.erl stdlib_test/*.erl src/mod/event/*.erl src/ranking/*.erl src/admin/*.erl src/user_event/*.erl src/activity/*.erl
include ../../../hrl/include.mk

##使用通配符方式指定每个文件的编译规则
$(EBIN_DIR)/%.$(EMULATOR): $(hrl) src/%.erl 
	$(ERLC) $(ERLC_FLAGS) -o $(EBIN_DIR) $<
	
$(EBIN_DIR)/%.$(EMULATOR): $(hrl) src/mod/%.erl 
	$(ERLC) $(ERLC_FLAGS) -o $(EBIN_DIR) $<

$(EBIN_DIR)/%.$(EMULATOR): $(hrl) stdlib_test/%.erl 
	$(ERLC) $(ERLC_FLAGS) -o $(EBIN_DIR) $<
	
$(EBIN_DIR)/%.$(EMULATOR): $(hrl) src/hook/%.erl 
	$(ERLC) $(ERLC_FLAGS) -o $(EBIN_DIR) $<
	
$(EBIN_DIR)/%.$(EMULATOR): $(hrl) src/mod/event/%.erl 
	$(ERLC) $(ERLC_FLAGS) -o $(EBIN_DIR) $<
	
$(EBIN_DIR)/%.$(EMULATOR): $(hrl) src/ranking/%.erl 
	$(ERLC) $(ERLC_FLAGS) -o $(EBIN_DIR) $<
	
$(EBIN_DIR)/%.$(EMULATOR): $(hrl) src/user_event/%.erl 
	$(ERLC) $(ERLC_FLAGS) -o $(EBIN_DIR) $<
	
$(EBIN_DIR)/%.$(EMULATOR): $(hrl) src/admin/%.erl 
	$(ERLC) $(ERLC_FLAGS) -o $(EBIN_DIR) $<
	
$(EBIN_DIR)/%.$(EMULATOR): $(hrl) src/activity/%.erl 
	$(ERLC) $(ERLC_FLAGS) -o $(EBIN_DIR) $<